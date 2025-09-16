use clap::Parser;
use rmcp::transport::sse_server::{SseServer, SseServerConfig};
use tracing_subscriber::{
    self,
    layer::SubscriberExt,
    util::SubscriberInitExt,
};
mod defi_trader;
mod protocols;
use defi_trader::DefiTrader;
mod config;
use config::Config;
use std::env;

/// A simple defi trader
#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Cli {
    /// The rpc url to connect to
    #[arg(short, long)]
    rpc_url: Option<String>,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "debug".to_string().into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    let cli = Cli::parse();

    let mut config: Config = toml::from_str(&std::fs::read_to_string("Config.toml")?)?;

    if let Some(rpc_url) = cli.rpc_url {
        config.rpc_url = rpc_url;
    }

    if let Ok(bind_address) = env::var("BIND_ADDRESS") {
        config.bind_address = bind_address;
    }

    let sse_config = SseServerConfig {
        bind: config.bind_address.parse()?,
        sse_path: "/sse".to_string(),
        post_path: "/message".to_string(),
        ct: tokio_util::sync::CancellationToken::new(),
        sse_keep_alive: None,
    };

    let (sse_server, router) = SseServer::new(sse_config);

    let listener = tokio::net::TcpListener::bind(sse_server.config.bind).await?;

    let ct = sse_server.config.ct.child_token();

    let server = axum::serve(listener, router).with_graceful_shutdown(async move {
        ct.cancelled().await;
        tracing::info!("sse server cancelled");
    });

    tokio::spawn(async move {
        if let Err(e) = server.await {
            tracing::error!(error = %e, "sse server shutdown with error");
        }
    });

    let defi_trader = DefiTrader::new(config.clone());

    let ct = sse_server.with_service(move || defi_trader.clone());

    tokio::signal::ctrl_c().await?;
    ct.cancel();
    Ok(())
}