/// Transport implementations for MCP server
use crate::config::Config;
use crate::mcp_service::AbiAssistantService;
use anyhow::Result;
use rmcp::transport::sse_server::{SseServer, SseServerConfig};
use rmcp::transport::streamable_http_server::{
    StreamableHttpService, 
    session::local::LocalSessionManager,
};
use tokio_util::sync::CancellationToken;
use tracing::{info, error};
use std::sync::Arc;

/// Transport mode for the server
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum TransportMode {
    Sse,
    Http,
    Unified,
    Both,
}

impl From<&str> for TransportMode {
    fn from(s: &str) -> Self {
        match s {
            "sse" => TransportMode::Sse,
            "http" => TransportMode::Http,
            "unified" => TransportMode::Unified,
            "both" => TransportMode::Both,
            _ => TransportMode::Unified,
        }
    }
}

/// Handle for managing server lifecycle
pub struct ServerHandle {
    cancellation_token: CancellationToken,
    join_handle: Option<tokio::task::JoinHandle<()>>,
}

impl ServerHandle {
    /// Create a new server handle
    pub fn new(cancellation_token: CancellationToken) -> Self {
        Self {
            cancellation_token,
            join_handle: None,
        }
    }
    
    /// Create a server handle with a join handle
    pub fn with_join_handle(
        cancellation_token: CancellationToken,
        join_handle: tokio::task::JoinHandle<()>,
    ) -> Self {
        Self {
            cancellation_token,
            join_handle: Some(join_handle),
        }
    }
    
    /// Wait for the server to shutdown
    pub async fn wait_for_shutdown(self) {
        // Wait for Ctrl+C or cancellation
        tokio::select! {
            _ = tokio::signal::ctrl_c() => {
                info!("Received shutdown signal");
                self.cancellation_token.cancel();
            }
            _ = self.cancellation_token.cancelled() => {
                info!("Server cancelled");
            }
        }
        
        // Wait for the server task to complete if we have a handle
        if let Some(handle) = self.join_handle {
            let _ = handle.await;
        }
    }
    
    /// Cancel the server
    pub fn cancel(&self) {
        self.cancellation_token.cancel();
    }
}

/// Start unified server (SSE + HTTP on same port)
pub async fn start_unified_server(
    config: &Config,
    service_factory: Arc<dyn Fn() -> AbiAssistantService + Send + Sync>,
) -> Result<ServerHandle> {
    let bind_address = config.get_bind_address("sse");
    info!("🚀 Starting Unified MCP Server on http://{}", bind_address);
    
    // Create SSE server configuration
    let sse_config = SseServerConfig {
        bind: bind_address.parse()?,
        sse_path: config.server.sse.path.clone(),
        post_path: config.server.sse.message_path.clone(),
        ct: CancellationToken::new(),
        sse_keep_alive: config.server.sse.keep_alive_interval
            .map(std::time::Duration::from_secs),
    };
    
    // Create SSE server and get its router
    let (sse_server, sse_router) = SseServer::new(sse_config);
    
    // Create HTTP service for streamable transport
    let factory = service_factory.clone();
    let http_service = StreamableHttpService::new(
        move || Ok(factory()),
        LocalSessionManager::default().into(),
        Default::default(),
    );
    
    // Combine both into a single router
    let unified_router = sse_router
        .route(&config.server.http.health_path, axum::routing::get(health_check))
        .fallback_service(http_service);
    
    // Bind to the address
    let listener = tokio::net::TcpListener::bind(&sse_server.config.bind).await?;
    
    info!("✅ SSE endpoint: http://{}{}", bind_address, config.server.sse.path);
    info!("✅ HTTP streaming endpoint: http://{}/", bind_address);
    info!("✅ Health check: http://{}{}", bind_address, config.server.http.health_path);
    
    let ct = sse_server.config.ct.child_token();
    let server_ct = ct.clone();
    
    // Create and start the unified server
    let server = axum::serve(listener, unified_router).with_graceful_shutdown(async move {
        server_ct.cancelled().await;
        info!("Unified server cancelled");
    });
    
    // Spawn the server task
    let server_handle = tokio::spawn(async move {
        if let Err(e) = server.await {
            error!("Unified server shutdown with error: {}", e);
        }
    });
    
    // Attach the MCP service to the SSE server
    let factory = service_factory.clone();
    let service_ct = sse_server.with_service(move || factory());
    
    Ok(ServerHandle::with_join_handle(service_ct, server_handle))
}

/// Start SSE-only server
pub async fn start_sse_server(
    config: &Config,
    service_factory: Arc<dyn Fn() -> AbiAssistantService + Send + Sync>,
) -> Result<ServerHandle> {
    let bind_address = config.get_bind_address("sse");
    info!("🚀 Starting MCP SSE Server on http://{}{}", bind_address, config.server.sse.path);
    
    // Create SSE server configuration
    let sse_config = SseServerConfig {
        bind: bind_address.parse()?,
        sse_path: config.server.sse.path.clone(),
        post_path: config.server.sse.message_path.clone(),
        ct: CancellationToken::new(),
        sse_keep_alive: config.server.sse.keep_alive_interval
            .map(std::time::Duration::from_secs),
    };
    
    // Create SSE server and router
    let (sse_server, router) = SseServer::new(sse_config);
    
    // Add health check to the router
    let router = router.route(&config.server.http.health_path, axum::routing::get(health_check));
    
    // Bind to the address
    let listener = tokio::net::TcpListener::bind(&sse_server.config.bind).await?;
    
    info!("✅ SSE endpoint ready at: http://{}{}", bind_address, config.server.sse.path);
    info!("✅ Health check at: http://{}{}", bind_address, config.server.http.health_path);
    
    let ct = sse_server.config.ct.child_token();
    let server_ct = ct.clone();
    
    // Create and start the axum server
    let server = axum::serve(listener, router).with_graceful_shutdown(async move {
        server_ct.cancelled().await;
        info!("SSE server cancelled");
    });
    
    // Spawn the server task
    let server_handle = tokio::spawn(async move {
        if let Err(e) = server.await {
            error!("SSE server shutdown with error: {}", e);
        }
    });
    
    // Attach the MCP service to the SSE server
    let factory = service_factory.clone();
    let service_ct = sse_server.with_service(move || factory());
    
    Ok(ServerHandle::with_join_handle(service_ct, server_handle))
}

/// Start HTTP-only server
pub async fn start_http_server(
    config: &Config,
    service_factory: Arc<dyn Fn() -> AbiAssistantService + Send + Sync>,
) -> Result<ServerHandle> {
    let bind_address = config.get_bind_address("http");
    info!("🚀 Starting MCP HTTP Server on http://{}/", bind_address);
    
    // Create HTTP service with local session manager
    let factory = service_factory.clone();
    let service = StreamableHttpService::new(
        move || Ok(factory()),
        LocalSessionManager::default().into(),
        Default::default(),
    );
    
    // Create router with the MCP service at root
    let router = axum::Router::new()
        .fallback_service(service)
        .route(&config.server.http.health_path, axum::routing::get(health_check));
    
    // Bind to the address
    let listener = tokio::net::TcpListener::bind(&bind_address).await?;
    
    info!("✅ HTTP streaming endpoint ready at: http://{}/", bind_address);
    info!("✅ Health check at: http://{}{}", bind_address, config.server.http.health_path);
    
    let ct = CancellationToken::new();
    let server_ct = ct.clone();
    
    // Start the server with graceful shutdown
    let server_handle = tokio::spawn(async move {
        let server = axum::serve(listener, router)
            .with_graceful_shutdown(async move {
                server_ct.cancelled().await;
                info!("HTTP server cancelled");
            });
        
        if let Err(e) = server.await {
            error!("HTTP server shutdown with error: {}", e);
        }
    });
    
    Ok(ServerHandle::with_join_handle(ct, server_handle))
}

/// Health check handler
async fn health_check() -> &'static str {
    "MCP Server is running"
}