use serde::{Deserialize, Serialize};
use serde_json::Value;

/// Tool definition for MCP
#[derive(Debug, Serialize, Deserialize)]
pub struct Tool {
    pub name: String,
    pub description: String,
    #[serde(rename = "inputSchema")]
    pub input_schema: Value,
}

/// Get all available tools
pub fn get_tools() -> Vec<Tool> {
    vec![
        Tool {
            name: "interpret_intent".to_string(),
            description: "Convert natural language to smart contract calls".to_string(),
            input_schema: serde_json::json!({
                "type": "object",
                "properties": {
                    "intent": {
                        "type": "string",
                        "description": "Natural language description of the desired action"
                    },
                    "chain": {
                        "type": "string",
                        "description": "Blockchain network (ethereum, polygon, etc.)",
                        "default": "ethereum"
                    }
                },
                "required": ["intent"]
            }),
        },
        Tool {
            name: "encode_function_call".to_string(),
            description: "Encode a function call with ABI".to_string(),
            input_schema: serde_json::json!({
                "type": "object",
                "properties": {
                    "function": {
                        "type": "string",
                        "description": "Function name"
                    },
                    "params": {
                        "type": "array",
                        "description": "Function parameters"
                    },
                    "abi": {
                        "type": "string",
                        "description": "Contract ABI (optional)"
                    }
                },
                "required": ["function"]
            }),
        },
        Tool {
            name: "decode_transaction".to_string(),
            description: "Decode transaction data into human-readable format".to_string(),
            input_schema: serde_json::json!({
                "type": "object",
                "properties": {
                    "data": {
                        "type": "string",
                        "description": "Encoded transaction data (hex)"
                    },
                    "abi": {
                        "type": "string",
                        "description": "Contract ABI (optional)"
                    }
                },
                "required": ["data"]
            }),
        },
        Tool {
            name: "estimate_gas".to_string(),
            description: "Estimate gas for a transaction".to_string(),
            input_schema: serde_json::json!({
                "type": "object",
                "properties": {
                    "to": {
                        "type": "string",
                        "description": "Contract address"
                    },
                    "data": {
                        "type": "string",
                        "description": "Transaction data"
                    },
                    "value": {
                        "type": "string",
                        "description": "ETH value to send",
                        "default": "0"
                    }
                },
                "required": ["to", "data"]
            }),
        },
    ]
}