use std::future::Future;
use rmcp::{
    ServerHandler,
    handler::server::{
        router::tool::ToolRouter,
        tool::Parameters,
    },
    model::{ServerCapabilities, ServerInfo, CallToolResult, Content},
    schemars, tool, tool_handler, tool_router,
    ErrorData as McpError,
};
use serde_json::json;
use tracing::{info, debug};

/// Input for interpret_intent tool
#[derive(Debug, serde::Deserialize, schemars::JsonSchema)]
pub struct InterpretIntentArgs {
    /// Natural language description of the desired action
    pub intent: String,
}

/// Input for encode_function_call tool
#[derive(Debug, serde::Deserialize, schemars::JsonSchema)]
pub struct EncodeFunctionArgs {
    /// Function name
    pub function: String,
    /// First parameter (typically address)
    #[serde(default)]
    pub param1: String,
    /// Second parameter (typically amount)
    #[serde(default)]
    pub param2: String,
}

/// Input for decode_transaction tool
#[derive(Debug, serde::Deserialize, schemars::JsonSchema)]
pub struct DecodeTransactionArgs {
    /// Transaction data to decode
    pub data: String,
}

/// ABI Assistant MCP Service implementation
#[derive(Clone)]
pub struct AbiAssistantService {
    tool_router: ToolRouter<AbiAssistantService>,
}

#[tool_router]
impl AbiAssistantService {
    pub fn new() -> Self {
        info!("Creating ABI Assistant MCP service");
        Self {
            tool_router: Self::tool_router(),
        }
    }
    
    #[tool(description = "Convert natural language to contract calls")]
    async fn interpret_intent(&self, Parameters(args): Parameters<InterpretIntentArgs>) -> Result<CallToolResult, McpError> {
        debug!("Interpreting intent: {}", args.intent);
        
        let result = if args.intent.contains("swap") || args.intent.contains("exchange") {
            json!({
                "protocol": "Uniswap",
                "function": "swapExactTokensForTokens",
                "confidence": 0.85
            })
        } else if args.intent.contains("transfer") || args.intent.contains("send") {
            json!({
                "protocol": "ERC20",
                "function": "transfer",
                "confidence": 0.90
            })
        } else if args.intent.contains("approve") {
            json!({
                "protocol": "ERC20",
                "function": "approve",
                "confidence": 0.95
            })
        } else {
            json!({
                "error": "Could not interpret intent",
                "confidence": 0.0
            })
        };
        
        Ok(CallToolResult::success(vec![
            Content::text(serde_json::to_string(&result).unwrap())
        ]))
    }
    
    #[tool(description = "Encode a function call with ABI")]
    async fn encode_function_call(&self, Parameters(args): Parameters<EncodeFunctionArgs>) -> Result<CallToolResult, McpError> {
        debug!("Encoding function: {} with params: {} {}", args.function, args.param1, args.param2);
        
        let result = match args.function.as_str() {
            "transfer" => {
                match crate::abi::encoder::AbiEncoder::encode_transfer(&args.param1, &args.param2) {
                    Ok(encoded) => json!({
                        "encoded": encoded,
                        "function": "transfer"
                    }),
                    Err(e) => json!({
                        "error": format!("Encoding failed: {}", e)
                    })
                }
            },
            "approve" => {
                match crate::abi::encoder::AbiEncoder::encode_approve(&args.param1, &args.param2) {
                    Ok(encoded) => json!({
                        "encoded": encoded,
                        "function": "approve"
                    }),
                    Err(e) => json!({
                        "error": format!("Encoding failed: {}", e)
                    })
                }
            },
            _ => json!({
                "error": format!("Unknown function: {}", args.function)
            })
        };
        
        Ok(CallToolResult::success(vec![
            Content::text(serde_json::to_string(&result).unwrap())
        ]))
    }
    
    #[tool(description = "Decode transaction data")]
    async fn decode_transaction(&self, Parameters(args): Parameters<DecodeTransactionArgs>) -> Result<CallToolResult, McpError> {
        debug!("Decoding transaction data: {}", args.data);
        
        match crate::abi::decoder::AbiDecoder::decode_function_call(&args.data) {
            Ok(decoded) => {
                let result = json!({
                    "success": true,
                    "function": decoded.function,
                    "params": decoded.params
                });
                Ok(CallToolResult::success(vec![
                    Content::text(serde_json::to_string(&result).unwrap())
                ]))
            },
            Err(e) => {
                let result = json!({
                    "success": false,
                    "error": format!("Failed to decode: {}", e)
                });
                Ok(CallToolResult::success(vec![
                    Content::text(serde_json::to_string(&result).unwrap())
                ]))
            }
        }
    }
    
    #[tool(description = "Estimate gas for a transaction")]
    async fn estimate_gas(&self) -> Result<CallToolResult, McpError> {
        debug!("Estimating gas for transaction");
        
        // Placeholder for now - would integrate with actual RPC
        let result = json!({
            "gasLimit": "150000",
            "gasPrice": "30000000000", // 30 gwei
            "estimatedCost": "0.0045" // in ETH
        });
        
        Ok(CallToolResult::success(vec![
            Content::text(serde_json::to_string(&result).unwrap())
        ]))
    }
}

// Implement the ServerHandler trait
#[tool_handler]
impl ServerHandler for AbiAssistantService {
    fn get_info(&self) -> ServerInfo {
        ServerInfo {
            instructions: Some("An MCP server for interacting with EVM smart contracts through natural language".into()),
            capabilities: ServerCapabilities::builder()
                .enable_tools()
                .build(),
            ..Default::default()
        }
    }
}