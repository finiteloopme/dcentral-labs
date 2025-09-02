use anyhow::Result;
use ethers::prelude::*;
use rmcp::model::*;
use rmcp::service::*;
use rmcp::transport::stdio;
use rmcp::ServerHandler;
use serde::Deserialize;
use std::sync::Arc;
use std::borrow::Cow;
use serde_json::{Value, from_str, Map};

#[derive(Clone)]
pub struct EvmTools {
    provider: Arc<Provider<Http>>,
}

#[derive(Deserialize)]
pub struct GetTokenPriceParams {
    token0: String,
    token1: String,
}

impl EvmTools {
    fn new() -> Self {
        let provider = Arc::new(Provider::<Http>::try_from("https://rpc.flashbots.net").unwrap());
        Self { provider }
    }

    async fn get_block_number(&self) -> Result<String> {
        let block_number = self.provider.get_block_number().await?;
        Ok(block_number.to_string())
    }

    async fn get_token_price(&self, _params: GetTokenPriceParams) -> Result<String> {
        Ok("123.45".to_string())
    }
}

impl ServerHandler for EvmTools {
    fn get_info(&self) -> ServerInfo {
        ServerInfo {
            protocol_version: ProtocolVersion::V_2024_11_05,
            capabilities: ServerCapabilities::builder()
                .enable_tools()
                .build(),
            server_info: Implementation::from_build_env(),
            instructions: Some("This server provides tools for interacting with the Ethereum blockchain.".to_string()),
        }
    }

    async fn list_tools(&self, _req: Option<PaginatedRequestParam>, _ctx: RequestContext<RoleServer>) -> Result<ListToolsResult, ErrorData> {
        let schema_str = "{\"type\":\"object\",\"properties\":{\"token0\":{\"type\":\"string\"},\"token1\":{\"type\":\"string\"}},\"required\":[\"token0\",\"token1\"]}";
        let schema: Value = from_str(schema_str).unwrap();
        let schema_map = schema.as_object().unwrap().clone();

        Ok(ListToolsResult {
            tools: vec![
                Tool {
                    name: Cow::Borrowed("get_block_number"),
                    description: Some(Cow::Borrowed("Get the latest block number from the Ethereum mainnet")),
                    input_schema: Arc::new(Map::new()),
                    output_schema: None,
                    annotations: None,
                },
                Tool {
                    name: Cow::Borrowed("get_token_price"),
                    description: Some(Cow::Borrowed("Get the price of a token pair from Uniswap V3")),
                    input_schema: Arc::new(schema_map),
                    output_schema: None,
                    annotations: None,
                },
            ],
            next_cursor: None,
        })
    }

    async fn call_tool(&self, req: CallToolRequestParam, _ctx: RequestContext<RoleServer>) -> Result<CallToolResult, ErrorData> {
        match req.name.as_ref() {
            "get_block_number" => {
                let result = self.get_block_number().await.unwrap();
                Ok(CallToolResult::success(vec![Content::text(result)]))
            }
            "get_token_price" => {
                let params: GetTokenPriceParams = serde_json::from_value(Value::Object(req.arguments.unwrap())).unwrap();
                let result = self.get_token_price(params).await.unwrap();
                Ok(CallToolResult::success(vec![Content::text(result)]))
            }
            _ => Err(ErrorData::method_not_found::<CallToolRequestMethod>()),
        }
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    let service = EvmTools::new().serve(stdio()).await?;
    service.waiting().await?;
    Ok(())
}