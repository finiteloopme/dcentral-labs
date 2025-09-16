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


/// The `DefiTrader` struct represents the DeFi trader service.
#[derive(Clone)]
pub struct DefiTrader {
    tool_router: ToolRouter<DefiTrader>,
    prompt_router: PromptRouter<DefiTrader>,
    config: Config,
    uniswap_v2: UniswapV2,
    curve: Curve,
    balancer: Balancer,
    sushiswap: SushiSwap,
}

#[tool_router]
impl DefiTrader {
    /// Creates a new `DefiTrader` instance.
    ///
    /// # Arguments
    ///
    /// * `config` - The configuration for the service.
    pub fn new(config: Config) -> Self {
        let uniswap_v2 = UniswapV2::new(
            &config.rpc_url,
            Address::from_str(&config.uniswap_v2_router).unwrap(),
        );
        let curve = Curve::new(
            &config.rpc_url,
            Address::from_str(&config.curve_registry).unwrap(),
        );
        let balancer = Balancer::new(
            &config.rpc_url,
            Address::from_str(&config.balancer_vault).unwrap(),
        );
        let sushiswap = SushiSwap::new(
            &config.rpc_url,
            Address::from_str(&config.sushiswap_router).unwrap(),
        );

        Self {
            tool_router: Self::tool_router(),
            prompt_router: Self::prompt_router(),
            config,
            uniswap_v2,
            curve,
            balancer,
            sushiswap,
        }
    }

    
    /// Returns a quote for a swap from a specific protocol.
    #[tool]
    async fn get_quote(&self, Parameters(args): Parameters<GetQuoteArgs>) -> Result<CallToolResult, McpError> {
        let from_token = args.from_token.parse::<Address>().map_err(|e| McpError::invalid_params(e.to_string(), None))?;
        let to_token = args.to_token.parse::<Address>().map_err(|e| McpError::invalid_params(e.to_string(), None))?;
        let amount = U256::from_dec_str(&args.amount).map_err(|e| McpError::invalid_params(e.to_string(), None))?;

        let quote = match args.protocol.as_str() {
            "uniswap_v2" => self.uniswap_v2.get_quote(from_token, to_token, amount).await,
            "curve" => self.curve.get_quote(from_token, to_token, amount).await,
            "balancer" => self.balancer.get_quote(from_token, to_token, amount).await,
            "sushiswap" => self.sushiswap.get_quote(from_token, to_token, amount).await,
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
            "uniswap_v2" => self.uniswap_v2.swap(from_token, to_token, amount).await,
            "curve" => self.curve.swap(from_token, to_token, amount).await,
            "balancer" => self.balancer.swap(from_token, to_token, amount).await,
            "sushiswap" => self.sushiswap.swap(from_token, to_token, amount).await,
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
            instructions: Some("This server provides tools for interacting with DeFi protocols.".to_string()),
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
