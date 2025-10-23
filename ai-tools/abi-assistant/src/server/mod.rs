/// MCP Server module - provides server functionality that can be used as a library
pub mod transport;
pub mod builder;

use crate::config::Config;
use crate::mcp_service::AbiAssistantService;
use anyhow::Result;
use tracing::{info, error};
use std::sync::Arc;

pub use builder::ServerBuilder;
pub use transport::{TransportMode, ServerHandle};

/// Main server struct that manages MCP server instances
pub struct Server {
    config: Config,
    service_factory: Arc<dyn Fn() -> AbiAssistantService + Send + Sync>,
}

impl Server {
    /// Create a new server with the given configuration
    pub fn new(config: Config) -> Self {
        Self {
            config,
            service_factory: Arc::new(|| AbiAssistantService::new()),
        }
    }
    
    /// Create a server builder for more flexible configuration
    pub fn builder() -> ServerBuilder {
        ServerBuilder::new()
    }
    
    /// Create a server with a custom service factory
    pub fn with_service_factory<F>(config: Config, factory: F) -> Self 
    where
        F: Fn() -> AbiAssistantService + Send + Sync + 'static,
    {
        Self {
            config,
            service_factory: Arc::new(factory),
        }
    }
    
    /// Run the server with the configured transport mode
    pub async fn run(self) -> Result<()> {
        match self.config.server.transport.as_str() {
            "sse" => self.run_sse().await,
            "http" => self.run_http().await,
            "unified" => self.run_unified().await,
            "both" => self.run_both().await,
            _ => {
                error!("Unknown transport mode: {}", self.config.server.transport);
                Err(anyhow::anyhow!("Unknown transport mode"))
            }
        }
    }
    
    /// Run SSE-only server
    pub async fn run_sse(self) -> Result<()> {
        let handle = transport::start_sse_server(&self.config, self.service_factory).await?;
        handle.wait_for_shutdown().await;
        Ok(())
    }
    
    /// Run HTTP-only server
    pub async fn run_http(self) -> Result<()> {
        let handle = transport::start_http_server(&self.config, self.service_factory).await?;
        handle.wait_for_shutdown().await;
        Ok(())
    }
    
    /// Run unified server (SSE + HTTP on same port)
    pub async fn run_unified(self) -> Result<()> {
        let handle = transport::start_unified_server(&self.config, self.service_factory).await?;
        handle.wait_for_shutdown().await;
        Ok(())
    }
    
    /// Run both servers on separate ports
    pub async fn run_both(self) -> Result<()> {
        let config_sse = self.config.clone();
        let config_http = self.config.clone();
        let factory_sse = self.service_factory.clone();
        let factory_http = self.service_factory.clone();
        
        // Start SSE server
        let sse_handle = tokio::spawn(async move {
            match transport::start_sse_server(&config_sse, factory_sse).await {
                Ok(handle) => {
                    handle.wait_for_shutdown().await;
                }
                Err(e) => {
                    error!("SSE server error: {}", e);
                }
            }
        });
        
        // Start HTTP server
        let http_handle = tokio::spawn(async move {
            match transport::start_http_server(&config_http, factory_http).await {
                Ok(handle) => {
                    handle.wait_for_shutdown().await;
                }
                Err(e) => {
                    error!("HTTP server error: {}", e);
                }
            }
        });
        
        info!("📌 Press Ctrl+C to stop all servers");
        
        // Wait for either server to exit or Ctrl+C
        tokio::select! {
            _ = sse_handle => {},
            _ = http_handle => {},
            _ = tokio::signal::ctrl_c() => {
                info!("Received shutdown signal");
            }
        }
        
        Ok(())
    }
    
    /// Get the configuration
    pub fn config(&self) -> &Config {
        &self.config
    }
    
    /// Log blockchain configuration
    pub fn log_blockchain_config(&self) {
        let config = &self.config;
        
        // Log Ethereum configuration
        if let Some(ref rpc_url) = config.blockchain.ethereum.rpc_url {
            info!("🔗 {} RPC URL: {}", config.blockchain.ethereum.name, rpc_url);
        }
        
        // Log other chains if enabled
        if let Some(ref polygon) = config.blockchain.polygon {
            if polygon.enabled.unwrap_or(false) {
                if let Some(ref rpc_url) = polygon.rpc_url {
                    info!("🔗 {} RPC URL: {}", polygon.name, rpc_url);
                }
            }
        }
        
        if let Some(ref arbitrum) = config.blockchain.arbitrum {
            if arbitrum.enabled.unwrap_or(false) {
                if let Some(ref rpc_url) = arbitrum.rpc_url {
                    info!("🔗 {} RPC URL: {}", arbitrum.name, rpc_url);
                }
            }
        }
        
        if let Some(ref optimism) = config.blockchain.optimism {
            if optimism.enabled.unwrap_or(false) {
                if let Some(ref rpc_url) = optimism.rpc_url {
                    info!("🔗 {} RPC URL: {}", optimism.name, rpc_url);
                }
            }
        }
        
        if let Some(ref base) = config.blockchain.base {
            if base.enabled.unwrap_or(false) {
                if let Some(ref rpc_url) = base.rpc_url {
                    info!("🔗 {} RPC URL: {}", base.name, rpc_url);
                }
            }
        }
        
        // Log feature flags
        if config.features.debug_mode {
            info!("🐛 Debug mode enabled");
        }
        
        if config.features.simulate_transactions {
            info!("✨ Transaction simulation enabled");
        }
        
        if config.features.gas_optimization {
            info!("⛽ Gas optimization enabled");
        }
        
        if config.features.mev_protection {
            info!("🛡️ MEV protection enabled");
        }
    }
}