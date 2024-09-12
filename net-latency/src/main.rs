use std::net::{IpAddr, Ipv4Addr};
use envconfig::Envconfig;
use http::Uri;
use rocket::figment::Figment;
use trippy::core::{Builder, PortDirection, PrivilegeMode, Protocol};
use trippy::dns::{DnsResolver,Resolver};

#[macro_use] extern crate rocket;

#[derive(Envconfig)]
pub struct  Config {
    #[envconfig(from = "GCP_REGION")]
    pub gcp_region: String,
    #[envconfig(from = "DESTINATION_HOSTS")]
    pub destination_hosts: String,
    #[envconfig(from="SAMPLE_SIZE", default="10")]
    pub sample_size: u16,
}


// #[tokio::main]
// fn main(){
//     std::env::set_var("GCP_REGION", "us-central1");
//     std::env::set_var("DESTINATION_HOSTS", "rbx.proof.ovh.net, https://relay-builders-direct-eu.ultrasound.money:3000, https://relay-builders-direct-us.ultrasound.money:3000, ec2-52-199-119-237.ap-northeast-1.compute.amazonaws.com");
//     let config = Config::init_from_env().unwrap();
//     check_latency(config.sample_size, config.destination_hosts);
// }

#[launch]
fn rocket() -> _ {
    std::env::set_var("GCP_REGION", "us-central1");
    std::env::set_var("DESTINATION_HOSTS", "");
    rocket::build()
        .configure(rocket::Config::figment().merge(("address", "0.0.0.0")).adjoin(("port", 8080)))
        .mount("/", routes![check_latency])
}

#[get("/<hosts>/<sample_size>")]
pub fn check_latency(sample_size: u16, hosts: String) -> String {
    let config = Config::init_from_env().unwrap();
    let resolver = DnsResolver::start(trippy::dns::Config::default()).unwrap();
    let mut result = String::from("source, dest_host, dest_ip, sample_count, resp_time_ms\n");
    // println!("source, dest_host, dest_ip, sample_count, resp_time_ms");
    for host in hosts.split(", "){
        println!("Checking latency for host: {}", host);
        let uri = host.parse::<Uri>().unwrap();
        let _host = uri.host().unwrap();
        let hostname = _host;
        let addrs: Vec<_> = resolver
            .lookup(&hostname)
            .map_err(|_| println!("unable to resolve dns for {}", hostname)).unwrap()
            .into_iter()
            .collect();
        let addr: IpAddr = match addrs.as_slice() {
            [] => {
                println!("traceroute: unknown host {}", hostname);
                IpAddr::V4(Ipv4Addr::new(240, 0, 0, 0))
            },
            [addr] => *addr,
            [addr, ..] => {
                println!("traceroute: Warning: {hostname} has multiple addresses; using {addr}");
                *addr
            }
        };
        // println!("host: {}", hostname);
        // let address = (host, 0).to_socket_addrs()?.map(|addr| addr.ip()).filter(|ip| ip.is_ipv4()).last().unwrap();
        // println!("host: {},  ip: {}", hostname, addr);
        let mut _duration = 0.0;
        for counter in 0..sample_size {
            let duration = traceroute(addr);
            let line = format!("{}, {}, {}, {}, {:.4?}\n", config.gcp_region, hostname, addr, counter, duration);
            result.push_str(&line);
            
            // println!("{}, {}, {}, {}, {:.4?}", config.gcp_region, hostname, addr, counter, duration);
            if _duration < duration {
                _duration = duration;
            }
        }
        // println!("{}, {}, {}, {}, {:.4?}", config.gcp_region, hostname, addr, "summary", _duration); 
        let summary = format!("{}, {}, {}, {}, {:.4?}\n", config.gcp_region, hostname, addr, "summary", _duration); 
        println!("{}", summary);
        result.push_str(&summary);
    }
    result
}

pub fn traceroute(ip: IpAddr) -> f64{
    // let host = parse_ip_from_uri_host(ip.to_string()).unwrap();
    let host = ip;
    let tracer = Builder::new(host)
        .privilege_mode(PrivilegeMode::Unprivileged)
        .protocol(Protocol::Udp)
        .port_direction(PortDirection::new_fixed_src(33434))
        .max_flows(1)
        .packet_size(40)
        .first_ttl(1)
        .max_ttl(5)
        .max_rounds(Some(3))
        .tos(0)
        .build().expect("error creating tracer");
    
    tracer.run().expect("error running tracing");
    let snapshot = &tracer.snapshot();
    let duration = snapshot.target_hop(snapshot.round_flow_id()).avg_ms();
    duration
}
