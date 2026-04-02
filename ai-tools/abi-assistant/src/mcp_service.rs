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
use tracing::{info, debug, warn, error};

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

/// Input for sign_transaction_unsafe tool (TEST ONLY)
#[derive(Debug, serde::Deserialize, schemars::JsonSchema)]
pub struct SignTransactionArgs {
    /// Transaction object to sign
    pub transaction: serde_json::Value,
    /// Private key (TEST KEY ONLY - without 0x prefix)
    pub private_key: String,
    /// Chain ID (1 for mainnet, 5 for goerli, 31337 for local)
    #[serde(default = "default_chain_id")]
    pub chain_id: u64,
}

fn default_chain_id() -> u64 {
    31337 // Local test chain
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
    
    #[tool(description = "Sign a transaction with a TEST private key (⚠️ TESTING ONLY - NEVER USE WITH REAL KEYS!)")]
    async fn sign_transaction_unsafe(&self, Parameters(args): Parameters<SignTransactionArgs>) -> Result<CallToolResult, McpError> {
        use crate::transaction::signer::TestTransactionSigner;
        
        warn!("⚠️ SECURITY WARNING: sign_transaction_unsafe called - this should ONLY be used for testing!");
        
        // First, show the security warning
        let warning = TestTransactionSigner::get_security_warning();
        debug!("{}", warning);
        
        // Attempt to sign the transaction
        let result = match TestTransactionSigner::sign_transaction_unsafe(
            &args.transaction,
            &args.private_key,
            args.chain_id,
        ) {
            Ok(signed) => {
                info!("Transaction signed successfully (TEST MODE)");
                json!({
                    "success": true,
                    "signed_transaction": signed,
                    "warning": warning,
                    "note": "This is a TEST signature. Never use this method with real private keys or on mainnet!"
                })
            },
            Err(e) => {
                error!("Failed to sign transaction: {}", e);
                json!({
                    "success": false,
                    "error": format!("{}", e),
                    "warning": warning,
                    "note": "Transaction signing failed. Make sure you're using a test key."
                })
            }
        };
        
        Ok(CallToolResult::success(vec![
            Content::text(serde_json::to_string_pretty(&result).unwrap())
        ]))
    }
    
    #[tool(description = "Get configured blockchain RPC endpoints and chain IDs")]
    async fn get_rpc_config(&self) -> Result<CallToolResult, McpError> {
        debug!("Getting RPC configuration");
        
        use crate::config::Config;
        
        // Load current configuration
        let config = Config::load()
            .map_err(|e| McpError::new(ErrorCode::INTERNAL_ERROR, format!("Failed to load config: {}", e), None))?;
        
        let mut chains = Vec::new();
        
        // Add Ethereum configuration
        let ethereum = &config.blockchain.ethereum;
        chains.push(json!({
            "name": ethereum.name,
            "chain_id": ethereum.chain_id,
            "rpc_url": ethereum.rpc_url.as_ref().unwrap_or(&"Not configured".to_string()),
            "enabled": true,
            "is_default": true
        }));
        
        // Add other chains if configured and enabled
        if let Some(ref polygon) = config.blockchain.polygon {
            if polygon.enabled.unwrap_or(false) {
                chains.push(json!({
                    "name": polygon.name,
                    "chain_id": polygon.chain_id,
                    "rpc_url": polygon.rpc_url.as_ref().unwrap_or(&"Not configured".to_string()),
                    "enabled": true,
                    "is_default": false
                }));
            }
        }
        
        if let Some(ref arbitrum) = config.blockchain.arbitrum {
            if arbitrum.enabled.unwrap_or(false) {
                chains.push(json!({
                    "name": arbitrum.name,
                    "chain_id": arbitrum.chain_id,
                    "rpc_url": arbitrum.rpc_url.as_ref().unwrap_or(&"Not configured".to_string()),
                    "enabled": true,
                    "is_default": false
                }));
            }
        }
        
        if let Some(ref optimism) = config.blockchain.optimism {
            if optimism.enabled.unwrap_or(false) {
                chains.push(json!({
                    "name": optimism.name,
                    "chain_id": optimism.chain_id,
                    "rpc_url": optimism.rpc_url.as_ref().unwrap_or(&"Not configured".to_string()),
                    "enabled": true,
                    "is_default": false
                }));
            }
        }
        
        if let Some(ref base) = config.blockchain.base {
            if base.enabled.unwrap_or(false) {
                chains.push(json!({
                    "name": base.name,
                    "chain_id": base.chain_id,
                    "rpc_url": base.rpc_url.as_ref().unwrap_or(&"Not configured".to_string()),
                    "enabled": true,
                    "is_default": false
                }));
            }
        }
        
        // Check connectivity to default chain
        let default_rpc = &config.blockchain.ethereum.rpc_url;
        let is_connected = if let Some(url) = default_rpc {
            // Simple connectivity check (could be enhanced)
            url.starts_with("http") || url.starts_with("ws")
        } else {
            false
        };
        
        let result = json!({
            "configured_chains": chains,
            "total_chains": chains.len(),
            "default_chain": {
                "name": config.blockchain.ethereum.name,
                "chain_id": config.blockchain.ethereum.chain_id,
                "rpc_url": config.blockchain.ethereum.rpc_url,
                "connected": is_connected
            },
            "features": {
                "simulation": config.features.simulate_transactions,
                "gas_optimization": config.features.gas_optimization,
                "mev_protection": config.features.mev_protection,
                "cross_chain": config.features.cross_chain
            }
        });
        
        Ok(CallToolResult::success(vec![
            Content::text(serde_json::to_string_pretty(&result).unwrap())
        ]))
    }
    
    #[tool(description = "Test connectivity to blockchain RPC endpoints")]
    async fn test_rpc_connection(&self) -> Result<CallToolResult, McpError> {
        debug!("Testing RPC connections");
        
        use crate::config::Config;
        
        let config = Config::load()
            .map_err(|e| McpError::new(ErrorCode::INTERNAL_ERROR, format!("Failed to load config: {}", e), None))?;
        
        let mut results = Vec::new();
        
        // Test Ethereum RPC
        if let Some(rpc_url) = &config.blockchain.ethereum.rpc_url {
            let test_result = test_rpc_endpoint(rpc_url, &config.blockchain.ethereum.name, config.blockchain.ethereum.chain_id).await;
            results.push(test_result);
        }
        
        // Test other chains if enabled
        if let Some(ref polygon) = config.blockchain.polygon {
            if polygon.enabled.unwrap_or(false) {
                if let Some(rpc_url) = &polygon.rpc_url {
                    let test_result = test_rpc_endpoint(rpc_url, &polygon.name, polygon.chain_id).await;
                    results.push(test_result);
                }
            }
        }
        
        if let Some(ref arbitrum) = config.blockchain.arbitrum {
            if arbitrum.enabled.unwrap_or(false) {
                if let Some(rpc_url) = &arbitrum.rpc_url {
                    let test_result = test_rpc_endpoint(rpc_url, &arbitrum.name, arbitrum.chain_id).await;
                    results.push(test_result);
                }
            }
        }
        
        let result = json!({
            "tested_endpoints": results.len(),
            "results": results,
            "summary": {
                "total": results.len(),
                "connected": results.iter().filter(|r| r["status"] == "connected").count(),
                "failed": results.iter().filter(|r| r["status"] != "connected").count()
            }
        });
        
        Ok(CallToolResult::success(vec![
            Content::text(serde_json::to_string_pretty(&result).unwrap())
        ]))
    }
    
    #[tool(description = "Send a signed transaction to the blockchain network via RPC")]
    async fn send_transaction(&self, Parameters(args): Parameters<SendTransactionArgs>) -> Result<CallToolResult, McpError> {
        info!("Sending transaction to network");
        
        use crate::config::Config;
        
        let config = Config::load()
            .map_err(|e| McpError::new(ErrorCode::INTERNAL_ERROR, format!("Failed to load config: {}", e), None))?;
        
        // Get RPC URL (use specified chain or default)
        let rpc_url = if let Some(chain_name) = &args.chain {
            match chain_name.to_lowercase().as_str() {
                "ethereum" | "eth" | "mainnet" => config.blockchain.ethereum.rpc_url,
                "polygon" | "matic" => config.blockchain.polygon.and_then(|c| c.rpc_url),
                "arbitrum" | "arb" => config.blockchain.arbitrum.and_then(|c| c.rpc_url),
                "optimism" | "op" => config.blockchain.optimism.and_then(|c| c.rpc_url),
                "base" => config.blockchain.base.and_then(|c| c.rpc_url),
                _ => config.blockchain.ethereum.rpc_url,
            }
        } else {
            config.blockchain.ethereum.rpc_url
        };
        
        let rpc_url = rpc_url.ok_or_else(|| 
            McpError::new(ErrorCode::INVALID_PARAMS, "No RPC URL configured", None)
        )?;
        
        // Send the transaction
        let result = send_raw_transaction(&rpc_url, &args.signed_transaction).await;
        
        match result {
            Ok(tx_hash) => {
                let response = json!({
                    "success": true,
                    "transaction_hash": tx_hash,
                    "rpc_url": rpc_url,
                    "message": format!("Transaction sent successfully: {}", tx_hash),
                    "explorer_url": get_explorer_url(&tx_hash, args.chain.as_deref())
                });
                
                Ok(CallToolResult::success(vec![
                    Content::text(serde_json::to_string_pretty(&response).unwrap())
                ]))
            },
            Err(e) => {
                let error_response = json!({
                    "success": false,
                    "error": format!("{}", e),
                    "rpc_url": rpc_url
                });
                
                Ok(CallToolResult::success(vec![
                    Content::text(serde_json::to_string_pretty(&error_response).unwrap())
                ]))
            }
        }
    }
    
    #[tool(description = "Get transaction status and receipt from the blockchain")]
    async fn get_transaction_status(&self, Parameters(args): Parameters<GetTransactionStatusArgs>) -> Result<CallToolResult, McpError> {
        debug!("Getting transaction status for: {}", args.transaction_hash);
        
        use crate::config::Config;
        
        let config = Config::load()
            .map_err(|e| McpError::new(ErrorCode::INTERNAL_ERROR, format!("Failed to load config: {}", e), None))?;
        
        // Get RPC URL
        let rpc_url = if let Some(chain_name) = &args.chain {
            match chain_name.to_lowercase().as_str() {
                "ethereum" | "eth" | "mainnet" => config.blockchain.ethereum.rpc_url,
                "polygon" | "matic" => config.blockchain.polygon.and_then(|c| c.rpc_url),
                "arbitrum" | "arb" => config.blockchain.arbitrum.and_then(|c| c.rpc_url),
                "optimism" | "op" => config.blockchain.optimism.and_then(|c| c.rpc_url),
                "base" => config.blockchain.base.and_then(|c| c.rpc_url),
                _ => config.blockchain.ethereum.rpc_url,
            }
        } else {
            config.blockchain.ethereum.rpc_url
        };
        
        let rpc_url = rpc_url.ok_or_else(|| 
            McpError::new(ErrorCode::INVALID_PARAMS, "No RPC URL configured", None)
        )?;
        
        // Get transaction receipt
        let result = get_transaction_receipt(&rpc_url, &args.transaction_hash).await;
        
        match result {
            Ok(receipt) => {
                Ok(CallToolResult::success(vec![
                    Content::text(serde_json::to_string_pretty(&receipt).unwrap())
                ]))
            },
            Err(e) => {
                let error_response = json!({
                    "success": false,
                    "error": format!("{}", e),
                    "transaction_hash": args.transaction_hash,
                    "message": "Transaction may be pending or not found"
                });
                
                Ok(CallToolResult::success(vec![
                    Content::text(serde_json::to_string_pretty(&error_response).unwrap())
                ]))
            }
        }
    }
}

/// Input for send_transaction tool
#[derive(Debug, serde::Deserialize, schemars::JsonSchema)]
pub struct SendTransactionArgs {
    /// The signed transaction hex string (with 0x prefix)
    pub signed_transaction: String,
    /// Optional: specify which chain to send to (default: ethereum)
    #[serde(default)]
    pub chain: Option<String>,
}

/// Input for get_transaction_status tool
#[derive(Debug, serde::Deserialize, schemars::JsonSchema)]
pub struct GetTransactionStatusArgs {
    /// The transaction hash to check
    pub transaction_hash: String,
    /// Optional: specify which chain to query (default: ethereum)
    #[serde(default)]
    pub chain: Option<String>,
}

/// Helper function to send raw transaction via RPC
async fn send_raw_transaction(rpc_url: &str, signed_tx: &str) -> Result<String, Box<dyn std::error::Error>> {
    use reqwest;
    
    let client = reqwest::Client::new();
    
    let request = json!({
        "jsonrpc": "2.0",
        "method": "eth_sendRawTransaction",
        "params": [signed_tx],
        "id": 1
    });
    
    let response = client.post(rpc_url)
        .json(&request)
        .send()
        .await?;
    
    if response.status().is_success() {
        let data: serde_json::Value = response.json().await?;
        
        if let Some(result) = data.get("result") {
            Ok(result.as_str().unwrap_or("").to_string())
        } else if let Some(error) = data.get("error") {
            Err(format!("RPC error: {}", error).into())
        } else {
            Err("Invalid RPC response".into())
        }
    } else {
        Err(format!("HTTP error: {}", response.status()).into())
    }
}

/// Helper function to get transaction receipt via RPC
async fn get_transaction_receipt(rpc_url: &str, tx_hash: &str) -> Result<serde_json::Value, Box<dyn std::error::Error>> {
    use reqwest;
    
    let client = reqwest::Client::new();
    
    let request = json!({
        "jsonrpc": "2.0",
        "method": "eth_getTransactionReceipt",
        "params": [tx_hash],
        "id": 1
    });
    
    let response = client.post(rpc_url)
        .json(&request)
        .send()
        .await?;
    
    if response.status().is_success() {
        let data: serde_json::Value = response.json().await?;
        
        if let Some(result) = data.get("result") {
            if result.is_null() {
                Ok(json!({
                    "status": "pending",
                    "transaction_hash": tx_hash,
                    "message": "Transaction is pending or not yet mined"
                }))
            } else {
                // Parse the receipt
                let status = result.get("status")
                    .and_then(|s| s.as_str())
                    .unwrap_or("unknown");
                
                let block_number = result.get("blockNumber")
                    .and_then(|b| b.as_str())
                    .unwrap_or("pending");
                
                let gas_used = result.get("gasUsed")
                    .and_then(|g| g.as_str())
                    .unwrap_or("0x0");
                
                Ok(json!({
                    "success": true,
                    "status": if status == "0x1" { "success" } else { "failed" },
                    "transaction_hash": tx_hash,
                    "block_number": block_number,
                    "gas_used": gas_used,
                    "receipt": result
                }))
            }
        } else if let Some(error) = data.get("error") {
            Err(format!("RPC error: {}", error).into())
        } else {
            Err("Invalid RPC response".into())
        }
    } else {
        Err(format!("HTTP error: {}", response.status()).into())
    }
}

/// Get block explorer URL for a transaction
fn get_explorer_url(tx_hash: &str, chain: Option<&str>) -> String {
    let base_url = match chain.map(|c| c.to_lowercase()).as_deref() {
        Some("polygon") | Some("matic") => "https://polygonscan.com/tx/",
        Some("arbitrum") | Some("arb") => "https://arbiscan.io/tx/",
        Some("optimism") | Some("op") => "https://optimistic.etherscan.io/tx/",
        Some("base") => "https://basescan.org/tx/",
        Some("goerli") => "https://goerli.etherscan.io/tx/",
        Some("sepolia") => "https://sepolia.etherscan.io/tx/",
        _ => "https://etherscan.io/tx/", // Default to mainnet
    };
    
    format!("{}{}", base_url, tx_hash)
}

/// Helper function to test RPC endpoint connectivity
async fn test_rpc_endpoint(url: &str, name: &str, expected_chain_id: u64) -> serde_json::Value {
    use reqwest;
    use std::time::Duration;
    
    let client = reqwest::Client::builder()
        .timeout(Duration::from_secs(5))
        .build()
        .unwrap_or_else(|_| reqwest::Client::new());
    
    // Test with eth_chainId call
    let request = json!({
        "jsonrpc": "2.0",
        "method": "eth_chainId",
        "params": [],
        "id": 1
    });
    
    match client.post(url)
        .json(&request)
        .send()
        .await
    {
        Ok(response) => {
            if response.status().is_success() {
                match response.json::<serde_json::Value>().await {
                    Ok(data) => {
                        if let Some(result) = data.get("result") {
                            // Parse chain ID from hex
                            let chain_id_hex = result.as_str().unwrap_or("0x0");
                            let chain_id = u64::from_str_radix(chain_id_hex.trim_start_matches("0x"), 16).unwrap_or(0);
                            
                            let matches_expected = chain_id == expected_chain_id;
                            
                            json!({
                                "name": name,
                                "url": url,
                                "status": "connected",
                                "chain_id": chain_id,
                                "expected_chain_id": expected_chain_id,
                                "chain_id_matches": matches_expected,
                                "message": if matches_expected {
                                    format!("Connected to {} (chain ID: {})", name, chain_id)
                                } else {
                                    format!("Connected but chain ID mismatch! Expected {} but got {}", expected_chain_id, chain_id)
                                }
                            })
                        } else if let Some(error) = data.get("error") {
                            json!({
                                "name": name,
                                "url": url,
                                "status": "error",
                                "message": format!("RPC error: {}", error)
                            })
                        } else {
                            json!({
                                "name": name,
                                "url": url,
                                "status": "error",
                                "message": "Invalid RPC response"
                            })
                        }
                    }
                    Err(e) => {
                        json!({
                            "name": name,
                            "url": url,
                            "status": "error",
                            "message": format!("Failed to parse response: {}", e)
                        })
                    }
                }
            } else {
                json!({
                    "name": name,
                    "url": url,
                    "status": "error",
                    "message": format!("HTTP error: {}", response.status())
                })
            }
        }
        Err(e) => {
            json!({
                "name": name,
                "url": url,
                "status": "offline",
                "message": format!("Connection failed: {}", e)
            })
        }
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