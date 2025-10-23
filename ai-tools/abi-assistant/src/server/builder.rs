/// Builder pattern for constructing MCP servers
use crate::config::Config;
use crate::mcp_service::AbiAssistantService;
use crate::server::Server;
use crate::storage;
use anyhow::Result;
use tracing::{info, error};
use tracing_subscriber::{
    layer::SubscriberExt,
    util::SubscriberInitExt,
    EnvFilter,
};

/// Builder for creating and configuring MCP servers
pub struct ServerBuilder {
    config: Option<Config>,
    service_factory: Option<Box<dyn Fn() -> AbiAssistantService + Send + Sync>>,
    init_logging: bool,
    init_database: bool,
    log_config: bool,
}

impl ServerBuilder {
    /// Create a new server builder
    pub fn new() -> Self {
        Self {
            config: None,
            service_factory: None,
            init_logging: true,
            init_database: true,
            log_config: true,
        }
    }
    
    /// Set the configuration
    pub fn with_config(mut self, config: Config) -> Self {
        self.config = Some(config);
        self
    }
    
    /// Load configuration from default sources
    pub fn with_default_config(mut self) -> Result<Self> {
        self.config = Some(Config::load()?);
        Ok(self)
    }
    
    /// Set a custom service factory
    pub fn with_service_factory<F>(mut self, factory: F) -> Self 
    where
        F: Fn() -> AbiAssistantService + Send + Sync + 'static,
    {
        self.service_factory = Some(Box::new(factory));
        self
    }
    
    /// Set whether to initialize logging (default: true)
    pub fn init_logging(mut self, init: bool) -> Self {
        self.init_logging = init;
        self
    }
    
    /// Set whether to initialize database (default: true)
    pub fn init_database(mut self, init: bool) -> Self {
        self.init_database = init;
        self
    }
    
    /// Set whether to log configuration (default: true)
    pub fn log_config(mut self, log: bool) -> Self {
        self.log_config = log;
        self
    }
    
    /// Build the server
    pub async fn build(mut self) -> Result<Server> {
        // Get config or load default
        let config = match self.config.take() {
            Some(c) => c,
            None => Config::load()?,
        };
        
        // Initialize logging if requested
        if self.init_logging {
            Self::initialize_logging(&config)?;
        }
        
        // Log server info
        info!("Starting {} v{}", config.server.name, config.server.version);
        info!("{}", config.server.description);
        
        // Initialize database if requested
        if self.init_database {
            Self::initialize_database(&config).await?;
        }
        
        // Create the server
        let server = match self.service_factory {
            Some(factory) => Server::with_service_factory(config, factory),
            None => Server::new(config),
        };
        
        // Log configuration if requested
        if self.log_config {
            server.log_blockchain_config();
        }
        
        Ok(server)
    }
    
    /// Initialize logging based on configuration
    fn initialize_logging(config: &Config) -> Result<()> {
        let filter = EnvFilter::try_from_default_env()
            .unwrap_or_else(|_| EnvFilter::new(&config.logging.level));
        
        tracing_subscriber::registry()
            .with(filter)
            .with(tracing_subscriber::fmt::layer())
            .try_init()
            .map_err(|e| anyhow::anyhow!("Failed to initialize logging: {}", e))?;
        
        Ok(())
    }
    
    /// Initialize database
    async fn initialize_database(config: &Config) -> Result<()> {
        match storage::init_database(&config.database.url).await {
            Ok(_) => {
                info!("Database initialized successfully");
                Ok(())
            }
            Err(e) => {
                error!("Failed to initialize database: {}", e);
                Err(anyhow::anyhow!("Database initialization failed: {}", e))
            }
        }
    }
}

impl Default for ServerBuilder {
    fn default() -> Self {
        Self::new()
    }
}