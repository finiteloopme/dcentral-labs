mod coprocessor;
use dotenv::dotenv;

#[tokio::main]
async fn main() {
    dotenv().ok();
    std::env::set_var("HOST ", "0.0.0.0");
    std::env::set_var("PORT ", "8545");
    println!("Listening for ImageUploaded events...");
    let _ = coprocessor::eth::chain::run(
        "ws://0.0.0.0:8545".to_string(),
        "0x5FbDB2315678afecb367f032d93F642f64180aa3".parse().unwrap()
    ).await;
    println!("...done processing events");
}
