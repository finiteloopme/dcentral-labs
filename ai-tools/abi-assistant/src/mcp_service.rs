use std::future::Future;
use rmcp::{
    ServerHandler,
    handler::server::{
        router::tool::ToolRouter,
        tool::Parameters,
    },
    model::{ServerCapabilities, ServerInfo, CallToolResult, Content, ErrorCode},
    schemars, tool, tool_handler, tool_router,
    ErrorData as McpError,
};
use serde_json::json;
use crate::intent::resolver::IntentResolver;
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
    /// Function signature (e.g., "transfer(address,uint256)")
    pub signature: String,
    /// Parameters as JSON array
    pub parameters: serde_json::Value,
}

/// Input for decode_transaction tool
#[derive(Debug, serde::Deserialize, schemars::JsonSchema)]
pub struct DecodeTransactionArgs {
    /// Transaction data to decode
    pub data: String,
}

/// Input for build_transaction tool
#[derive(Debug, serde::Deserialize, schemars::JsonSchema)]
pub struct BuildTransactionArgs {
    /// Type of transaction (transfer, approve, swap, supply, etc.)
    pub transaction_type: String,
    /// Protocol name (optional)
    #[serde(default)]
    pub protocol: String,
    /// Parameters for the transaction
    pub parameters: serde_json::Value,
}

/// Input for export_for_signing tool
#[derive(Debug, serde::Deserialize, schemars::JsonSchema)]
pub struct ExportTransactionArgs {
    /// Transaction object to export
    pub transaction: serde_json::Value,
    /// Export format (raw_json, eip712, qr_code, wallet_connect, ethers_js, raw_hex)
    #[serde(default = "default_export_format")]
    pub format: String,
}

fn default_export_format() -> String {
    "raw_json".to_string()
}

/// ABI Assistant MCP Service implementation
#[derive(Clone)]
pub struct AbiAssistantService {
    tool_router: ToolRouter<AbiAssistantService>,
    intent_resolver: IntentResolver,
}

#[tool_router]
impl AbiAssistantService {
    pub fn new() -> Self {
        info!("Creating ABI Assistant MCP service");
        Self {
            tool_router: Self::tool_router(),
            intent_resolver: IntentResolver::new(),
        }
    }
    
    #[tool(description = "Convert natural language to contract calls")]
    async fn interpret_intent(&self, Parameters(args): Parameters<InterpretIntentArgs>) -> Result<CallToolResult, McpError> {
        debug!("Interpreting intent: {}", args.intent);
        
        // Use the intent resolver to interpret the intent
        match self.intent_resolver.resolve(&args.intent) {
            Ok(resolved) => {
                let mut suggestions = Vec::new();
                
                for (i, call) in resolved.contract_calls.iter().take(3).enumerate() {
                    suggestions.push(json!({
                        "rank": i + 1,
                        "protocol": call.protocol_name,
                        "contract": call.contract_address,
                        "function": call.function_name,
                        "parameters": call.parameters,
                        "confidence": call.confidence,
                        "gas_estimate": call.estimated_gas
                    }));
                }
                
                let result = json!({
                    "category": resolved.category.as_string(),
                    "confidence": resolved.confidence,
                    "parameters": resolved.parameters,
                    "suggestions": suggestions
                });
                
                Ok(CallToolResult::success(vec![
                    Content::text(serde_json::to_string_pretty(&result).unwrap())
                ]))
            },
            Err(e) => {
                let result = json!({
                    "error": format!("Failed to interpret intent: {}", e),
                    "confidence": 0.0
                });
                
                Ok(CallToolResult::success(vec![
                    Content::text(serde_json::to_string(&result).unwrap())
                ]))
            }
        }
    }
    
    #[tool(description = "Encode a function call with ABI")]
    async fn encode_function_call(&self, Parameters(args): Parameters<EncodeFunctionArgs>) -> Result<CallToolResult, McpError> {
        debug!("Encoding function: {} with params: {:?}", args.signature, args.parameters);
        
        let result = match crate::abi::encoder::AbiEncoder::encode_function(&args.signature, &args.parameters) {
            Ok(encoded) => json!({
                "success": true,
                "signature": args.signature,
                "encoded": encoded,
                "selector": &encoded[2..10], // First 4 bytes after 0x
                "data_length": (encoded.len() - 2) / 2, // Bytes count
            }),
            Err(e) => json!({
                "success": false,
                "error": format!("Encoding failed: {}", e)
            })
        };
        
        Ok(CallToolResult::success(vec![
            Content::text(serde_json::to_string_pretty(&result).unwrap())
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
    
    #[tool(description = "Build a transaction for signing")]
    async fn build_transaction(&self, Parameters(args): Parameters<BuildTransactionArgs>) -> Result<CallToolResult, McpError> {
        debug!("Building transaction: {} with params: {:?}", args.transaction_type, args.parameters);
        
        use crate::transaction::builder;
        
        let result = match args.transaction_type.as_str() {
            "transfer" | "token_transfer" => {
                // Extract parameters
                let params = args.parameters.as_object()
                    .ok_or_else(|| McpError::new(ErrorCode::INVALID_PARAMS, "Invalid parameters", None))?;
                
                let token_address = params.get("token_address")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| McpError::new(ErrorCode::INVALID_PARAMS, "Missing token_address", None))?;
                
                let to = params.get("to")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| McpError::new(ErrorCode::INVALID_PARAMS, "Missing to address", None))?;
                
                let amount = params.get("amount")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| McpError::new(ErrorCode::INVALID_PARAMS, "Missing amount", None))?;
                
                let from = params.get("from").and_then(|v| v.as_str());
                
                match builder::build_token_transfer(token_address, to, amount, from) {
                    Ok(tx) => json!({
                        "success": true,
                        "transaction": tx,
                        "type": "ERC20 Transfer"
                    }),
                    Err(e) => json!({
                        "success": false,
                        "error": format!("Failed to build transfer: {}", e)
                    })
                }
            },
            "approve" | "token_approval" => {
                let params = args.parameters.as_object()
                    .ok_or_else(|| McpError::new(ErrorCode::INVALID_PARAMS, "Invalid parameters", None))?;
                
                let token_address = params.get("token_address")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| McpError::new(ErrorCode::INVALID_PARAMS, "Missing token_address", None))?;
                
                let spender = params.get("spender")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| McpError::new(ErrorCode::INVALID_PARAMS, "Missing spender", None))?;
                
                let amount = params.get("amount")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| McpError::new(ErrorCode::INVALID_PARAMS, "Missing amount", None))?;
                
                let from = params.get("from").and_then(|v| v.as_str());
                
                match builder::build_token_approval(token_address, spender, amount, from) {
                    Ok(tx) => json!({
                        "success": true,
                        "transaction": tx,
                        "type": "ERC20 Approval"
                    }),
                    Err(e) => json!({
                        "success": false,
                        "error": format!("Failed to build approval: {}", e)
                    })
                }
            },
            "eth_transfer" => {
                let params = args.parameters.as_object()
                    .ok_or_else(|| McpError::new(ErrorCode::INVALID_PARAMS, "Invalid parameters", None))?;
                
                let to = params.get("to")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| McpError::new(ErrorCode::INVALID_PARAMS, "Missing to address", None))?;
                
                let amount = params.get("amount")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| McpError::new(ErrorCode::INVALID_PARAMS, "Missing amount", None))?;
                
                let from = params.get("from").and_then(|v| v.as_str());
                
                match builder::build_eth_transfer(to, amount, from) {
                    Ok(tx) => json!({
                        "success": true,
                        "transaction": tx,
                        "type": "ETH Transfer"
                    }),
                    Err(e) => json!({
                        "success": false,
                        "error": format!("Failed to build ETH transfer: {}", e)
                    })
                }
            },
            "swap" => {
                let params = args.parameters.as_object()
                    .ok_or_else(|| McpError::new(ErrorCode::INVALID_PARAMS, "Invalid parameters", None))?;
                
                let router_address = params.get("router_address")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| McpError::new(ErrorCode::INVALID_PARAMS, "Missing router_address", None))?;
                
                let amount_in = params.get("amount_in")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| McpError::new(ErrorCode::INVALID_PARAMS, "Missing amount_in", None))?;
                
                let amount_out_min = params.get("amount_out_min")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| McpError::new(ErrorCode::INVALID_PARAMS, "Missing amount_out_min", None))?;
                
                let path = params.get("path")
                    .and_then(|v| v.as_array())
                    .and_then(|arr| {
                        arr.iter()
                            .map(|v| v.as_str().map(String::from))
                            .collect::<Option<Vec<String>>>()
                    })
                    .ok_or_else(|| McpError::new(ErrorCode::INVALID_PARAMS, "Invalid path array", None))?;
                
                let to = params.get("to")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| McpError::new(ErrorCode::INVALID_PARAMS, "Missing to address", None))?;
                
                let deadline = params.get("deadline")
                    .and_then(|v| v.as_str())
                    .unwrap_or("9999999999");
                
                let from = params.get("from").and_then(|v| v.as_str());
                
                match builder::build_uniswap_swap(router_address, amount_in, amount_out_min, path, to, deadline, from) {
                    Ok(tx) => json!({
                        "success": true,
                        "transaction": tx,
                        "type": "Uniswap Swap"
                    }),
                    Err(e) => json!({
                        "success": false,
                        "error": format!("Failed to build swap: {}", e)
                    })
                }
            },
            _ => json!({
                "success": false,
                "error": format!("Unknown transaction type: {}", args.transaction_type),
                "supported_types": ["transfer", "approve", "eth_transfer", "swap"]
            })
        };
        
        Ok(CallToolResult::success(vec![
            Content::text(serde_json::to_string_pretty(&result).unwrap())
        ]))
    }
    
    #[tool(description = "Export transaction for signing in various formats")]
    async fn export_for_signing(&self, Parameters(args): Parameters<ExportTransactionArgs>) -> Result<CallToolResult, McpError> {
        debug!("Exporting transaction in format: {}", args.format);
        
        use crate::transaction::{builder::Transaction, formatter::{TransactionFormatter, ExportFormat}};
        
        // Parse transaction from JSON
        let tx: Transaction = match serde_json::from_value(args.transaction) {
            Ok(tx) => tx,
            Err(e) => {
                let result = json!({
                    "success": false,
                    "error": format!("Invalid transaction: {}", e)
                });
                return Ok(CallToolResult::success(vec![
                    Content::text(serde_json::to_string(&result).unwrap())
                ]));
            }
        };
        
        let format = match args.format.as_str() {
            "raw_json" => ExportFormat::RawJson,
            "eip712" => ExportFormat::Eip712,
            "qr_code" => ExportFormat::QrCode,
            "wallet_connect" => ExportFormat::WalletConnect,
            "ethers_js" => ExportFormat::EthersJs,
            "raw_hex" => ExportFormat::RawHex,
            "all" => {
                // Special case: export in all formats
                match TransactionFormatter::export_all_formats(&tx) {
                    Ok(result) => {
                        return Ok(CallToolResult::success(vec![
                            Content::text(serde_json::to_string_pretty(&result).unwrap())
                        ]));
                    },
                    Err(e) => {
                        let result = json!({
                            "success": false,
                            "error": format!("Export failed: {}", e)
                        });
                        return Ok(CallToolResult::success(vec![
                            Content::text(serde_json::to_string(&result).unwrap())
                        ]));
                    }
                }
            },
            _ => {
                let result = json!({
                    "success": false,
                    "error": format!("Unknown format: {}", args.format),
                    "supported_formats": ["raw_json", "eip712", "qr_code", "wallet_connect", "ethers_js", "raw_hex", "all"]
                });
                return Ok(CallToolResult::success(vec![
                    Content::text(serde_json::to_string(&result).unwrap())
                ]));
            }
        };
        
        let result = match TransactionFormatter::export(&tx, format) {
            Ok(exported) => json!({
                "success": true,
                "format": args.format,
                "data": exported
            }),
            Err(e) => json!({
                "success": false,
                "error": format!("Export failed: {}", e)
            })
        };
        
        Ok(CallToolResult::success(vec![
            Content::text(serde_json::to_string_pretty(&result).unwrap())
        ]))
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