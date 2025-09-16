// This module contains the `DefiTrader` service, which provides tools for interacting with DeFi protocols.

#![allow(dead_code)]

use rmcp::{
    ErrorData as McpError, RoleServer, ServerHandler,
    handler::server::{
        router::{prompt::PromptRouter, tool::ToolRouter},
        wrapper::Parameters,
    },
    model::*,
    prompt_handler, prompt_router,
    service::RequestContext,
    tool_handler, tool_router, tool, schemars,
};
use crate::config::Config;
use crate::protocols::{
    uniswap_v2::UniswapV2,
    curve::Curve,
    balancer::Balancer,
    sushiswap::SushiSwap,
};
use ethers::types::{Address, U256};
use std::str::FromStr;
use serde::Deserialize;
use std::sync::{Arc, Mutex};

#[derive(Deserialize, schemars::JsonSchema)]
pub struct GetQuoteArgs {
    pub protocol: String,
    pub from_token: String,
    pub to_token: String,
    pub amount: String,
}

#[derive(Deserialize, schemars::JsonSchema)]
pub struct SwapArgs {
    pub protocol: String,
    pub from_token: String,
    pub to_token: String,
    pub amount: String,
}

#[derive(Deserialize, schemars::JsonSchema)]
pub struct SetPrivateKeyArgs {
    pub private_key: String,
}

/// The `DefiTrader` struct represents the DeFi trader service.
#[derive(Clone)]
pub struct DefiTrader {
    tool_router: ToolRouter<DefiTrader>,
    prompt_router: PromptRouter<DefiTrader>,
    config: Config,
    uniswap_v2: Arc<Mutex<Option<UniswapV2>>>,
    curve: Arc<Mutex<Option<Curve>>>,
    balancer: Arc<Mutex<Option<Balancer>>>,
    sushiswap: Arc<Mutex<Option<SushiSwap>>>,
}

#[tool_router]
impl DefiTrader {
    /// Creates a new `DefiTrader` instance.
    ///
    /// # Arguments
    ///
    /// * `config` - The configuration for the service.
    pub fn new(config: Config) -> Self {
        Self {
            tool_router: Self::tool_router(),
            prompt_router: Self::prompt_router(),
            config,
            uniswap_v2: Arc::new(Mutex::new(None)),
            curve: Arc::new(Mutex::new(None)),
            balancer: Arc::new(Mutex::new(None)),
            sushiswap: Arc::new(Mutex::new(None)),
        }
    }

    /// Sets the private key for the service and initializes the protocols.
    #[tool]
    async fn set_private_key(&self, Parameters(args): Parameters<SetPrivateKeyArgs>) -> Result<CallToolResult, McpError> {
        let pk = args.private_key.clone();

        let uniswap_v2_protocol = UniswapV2::new(
            &self.config.rpc_url,
            Address::from_str(&self.config.uniswap_v2_router).unwrap(),
            &pk,
        ).await;
        
        let curve_protocol = Curve::new(
            &self.config.rpc_url,
            Address::from_str(&self.config.curve_registry).unwrap(),
            &pk,
        ).await;

        let balancer_protocol = Balancer::new(
            &self.config.rpc_url,
            Address::from_str(&self.config.balancer_vault).unwrap(),
            &pk,
        ).await;

        let sushiswap_protocol = SushiSwap::new(
            &self.config.rpc_url,
            Address::from_str(&self.config.sushiswap_router).unwrap(),
            &pk,
        ).await;

        let mut uniswap_v2 = self.uniswap_v2.lock().unwrap();
        *uniswap_v2 = Some(uniswap_v2_protocol);

        let mut curve = self.curve.lock().unwrap();
        *curve = Some(curve_protocol);

        let mut balancer = self.balancer.lock().unwrap();
        *balancer = Some(balancer_protocol);

        let mut sushiswap = self.sushiswap.lock().unwrap();
        *sushiswap = Some(sushiswap_protocol);

        Ok(CallToolResult::success(vec![Content::text(
            "Private key set and protocols initialized.".to_string(),
        )]))
    }

    
    /// Returns a quote for a swap from a specific protocol.
    #[tool]
    async fn get_quote(&self, Parameters(args): Parameters<GetQuoteArgs>) -> Result<CallToolResult, McpError> {
        let from_token = args.from_token.parse::<Address>().map_err(|e| McpError::invalid_params(e.to_string(), None))?;
        let to_token = args.to_token.parse::<Address>().map_err(|e| McpError::invalid_params(e.to_string(), None))?;
        let amount = U256::from_dec_str(&args.amount).map_err(|e| McpError::invalid_params(e.to_string(), None))?;

        let quote = match args.protocol.as_str() {
            "uniswap_v2" => {
                let protocol = {
                    let lock = self.uniswap_v2.lock().unwrap();
                    lock.clone()
                };
                if let Some(protocol) = protocol {
                    protocol.get_quote(from_token, to_token, amount).await
                } else {
                    return Err(McpError::internal_error("UniswapV2 not initialized. Please set the private key first.", None));
                }
            },
            "curve" => {
                let protocol = {
                    let lock = self.curve.lock().unwrap();
                    lock.clone()
                };
                if let Some(protocol) = protocol {
                    protocol.get_quote(from_token, to_token, amount).await
                } else {
                    return Err(McpError::internal_error("Curve not initialized. Please set the private key first.", None));
                }
            },
            "balancer" => {
                let protocol = {
                    let lock = self.balancer.lock().unwrap();
                    lock.clone()
                };
                if let Some(protocol) = protocol {
                    protocol.get_quote(from_token, to_token, amount).await
                } else {
                    return Err(McpError::internal_error("Balancer not initialized. Please set the private key first.", None));
                }
            },
            "sushiswap" => {
                let protocol = {
                    let lock = self.sushiswap.lock().unwrap();
                    lock.clone()
                };
                if let Some(protocol) = protocol {
                    protocol.get_quote(from_token, to_token, amount).await
                } else {
                    return Err(McpError::internal_error("SushiSwap not initialized. Please set the private key first.", None));
                }
            },
            _ => return Err(McpError::invalid_params("Invalid protocol", None)),
        }
        .map_err(|e| McpError::internal_error(e.to_string(), None))?;

        Ok(CallToolResult::success(vec![Content::text(
            quote.to_string(),
        )]))
    }

    /// Performs a swap on a specific protocol.
    #[tool]
    async fn swap(&self, Parameters(args): Parameters<SwapArgs>) -> Result<CallToolResult, McpError> {
        let from_token = args.from_token.parse::<Address>().map_err(|e| McpError::invalid_params(e.to_string(), None))?;
        let to_token = args.to_token.parse::<Address>().map_err(|e| McpError::invalid_params(e.to_string(), None))?;
        let amount = U256::from_dec_str(&args.amount).map_err(|e| McpError::invalid_params(e.to_string(), None))?;

        match args.protocol.as_str() {
            "uniswap_v2" => {
                let protocol = {
                    let lock = self.uniswap_v2.lock().unwrap();
                    lock.clone()
                };
                if let Some(protocol) = protocol {
                    protocol.swap(from_token, to_token, amount).await
                } else {
                    return Err(McpError::internal_error("UniswapV2 not initialized. Please set the private key first.", None));
                }
            },
            "curve" => {
                let protocol = {
                    let lock = self.curve.lock().unwrap();
                    lock.clone()
                };
                if let Some(protocol) = protocol {
                    protocol.swap(from_token, to_token, amount).await
                } else {
                    return Err(McpError::internal_error("Curve not initialized. Please set the private key first.", None));
                }
            },
            "balancer" => {
                let protocol = {
                    let lock = self.balancer.lock().unwrap();
                    lock.clone()
                };
                if let Some(protocol) = protocol {
                    protocol.swap(from_token, to_token, amount).await
                } else {
                    return Err(McpError::internal_error("Balancer not initialized. Please set the private key first.", None));
                }
            },
            "sushiswap" => {
                let protocol = {
                    let lock = self.sushiswap.lock().unwrap();
                    lock.clone()
                };
                if let Some(protocol) = protocol {
                    protocol.swap(from_token, to_token, amount).await
                } else {
                    return Err(McpError::internal_error("SushiSwap not initialized. Please set the private key first.", None));
                }
            },
            _ => return Err(McpError::invalid_params("Invalid protocol", None)),
        }
        .map_err(|e| McpError::internal_error(e.to_string(), None))?;

        Ok(CallToolResult::success(vec![Content::text(
            "Swapped".to_string(),
        )]))
    }
}

#[prompt_router]
impl DefiTrader {}

#[tool_handler]
#[prompt_handler]
impl ServerHandler for DefiTrader {
    /// Returns information about the service.
    fn get_info(&self) -> ServerInfo {
        ServerInfo {
            protocol_version: ProtocolVersion::V_2024_11_05,
            capabilities: ServerCapabilities::builder()
                .enable_tools()
                .build(),
            server_info: Implementation::from_build_env(),
            instructions: Some("This server provides tools for interacting with DeFi protocols. Please set the private key before using the swap tool.".to_string()),
        }
    }

    /// Initializes the service.
    async fn initialize(
        &self,
        _request: InitializeRequestParam,
        context: RequestContext<RoleServer>,
    ) -> Result<InitializeResult, McpError> {
        if let Some(http_request_part) = context.extensions.get::<axum::http::request::Parts>() {
            let initialize_headers = &http_request_part.headers;
            let initialize_uri = &http_request_part.uri;
            tracing::info!(?initialize_headers, %initialize_uri, "initialize from http server");
        }
        Ok(self.get_info())
    }
}