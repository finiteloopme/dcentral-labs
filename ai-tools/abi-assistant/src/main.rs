use abi_assistant::server::McpServer;
use abi_assistant::storage::init_database;
use std::env;
use tracing::{info, error};
use tracing_subscriber;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    // Initialize tracing
    tracing_subscriber::fmt::init();
    
    info!("Starting ABI Assistant MCP Server");
    
    // Initialize database
    let db_url = env::var("DATABASE_URL").unwrap_or_else(|_| "sqlite://./data/abi_assistant.db".to_string());
    match init_database(&db_url).await {
        Ok(_) => info!("Database initialized successfully"),
        Err(e) => {
            error!("Failed to initialize database: {}", e);
            return Err(e);
        }
    }
    
    // Get server port from environment or use default
    let port = env::var("MCP_PORT")
        .unwrap_or_else(|_| "3000".to_string())
        .parse::<u16>()
        .unwrap_or(3000);
    
    // Create and run server
    let server = McpServer::new(port);
    
    info!("Server starting on port {}", port);
    
    server.run().await
}