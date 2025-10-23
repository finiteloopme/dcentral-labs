use abi_assistant::server::Server;
use anyhow::Result;

#[tokio::main]
async fn main() -> Result<()> {
    // Build and run the server using the builder pattern
    let server = Server::builder()
        .with_default_config()?
        .init_logging(true)
        .init_database(true)
        .log_config(true)
        .build()
        .await?;
    
    // Run the server
    server.run().await?;
    
    Ok(())
}