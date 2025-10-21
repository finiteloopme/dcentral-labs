mod handlers;
mod tools;

use std::net::SocketAddr;
use hyper::{Body, Request, Response, Server, Method, StatusCode};
use hyper::service::{make_service_fn, service_fn};
use std::convert::Infallible;
use serde_json::{json, Value};
use tracing::{info, debug, error};

pub use handlers::*;
pub use tools::*;

/// MCP Server implementation
pub struct McpServer {
    port: u16,
}

impl McpServer {
    pub fn new(port: u16) -> Self {
        Self { port }
    }
    
    pub async fn run(&self) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        let addr = SocketAddr::from(([127, 0, 0, 1], self.port));
        
        let make_svc = make_service_fn(|_conn| async {
            Ok::<_, Infallible>(service_fn(handle_request))
        });
        
        let server = Server::bind(&addr).serve(make_svc);
        
        info!("MCP Server listening on http://{}", addr);
        
        server.await?;
        
        Ok(())
    }
}

async fn handle_request(req: Request<Body>) -> Result<Response<Body>, Infallible> {
    let response = match (req.method(), req.uri().path()) {
        (&Method::POST, "/") => {
            // Handle JSON-RPC requests
            handle_jsonrpc(req).await
        },
        (&Method::GET, "/health") => {
            Response::builder()
                .status(StatusCode::OK)
                .body(Body::from("OK"))
                .unwrap()
        },
        _ => {
            Response::builder()
                .status(StatusCode::NOT_FOUND)
                .body(Body::from("Not Found"))
                .unwrap()
        }
    };
    
    Ok(response)
}

async fn handle_jsonrpc(req: Request<Body>) -> Response<Body> {
    let body_bytes = match hyper::body::to_bytes(req.into_body()).await {
        Ok(bytes) => bytes,
        Err(e) => {
            error!("Failed to read request body: {}", e);
            return Response::builder()
                .status(StatusCode::BAD_REQUEST)
                .body(Body::from("Invalid request body"))
                .unwrap();
        }
    };
    
    let request: Value = match serde_json::from_slice(&body_bytes) {
        Ok(val) => val,
        Err(e) => {
            error!("Failed to parse JSON: {}", e);
            return Response::builder()
                .status(StatusCode::BAD_REQUEST)
                .body(Body::from("Invalid JSON"))
                .unwrap();
        }
    };
    
    debug!("Received JSON-RPC request: {:?}", request);
    
    // Process the JSON-RPC request
    let response = process_jsonrpc_request(request).await;
    
    Response::builder()
        .status(StatusCode::OK)
        .header("Content-Type", "application/json")
        .body(Body::from(serde_json::to_string(&response).unwrap()))
        .unwrap()
}

async fn process_jsonrpc_request(request: Value) -> Value {
    let method = request.get("method").and_then(|v| v.as_str()).unwrap_or("");
    let default_params = json!({});
    let params = request.get("params").unwrap_or(&default_params);
    let default_id = json!(null);
    let id = request.get("id").unwrap_or(&default_id);
    
    let result = match method {
        "tools/list" => {
            // Return list of available tools
            json!({
                "tools": [
                    {
                        "name": "interpret_intent",
                        "description": "Convert natural language to contract calls",
                        "inputSchema": {
                            "type": "object",
                            "properties": {
                                "intent": {
                                    "type": "string",
                                    "description": "Natural language description of the desired action"
                                }
                            },
                            "required": ["intent"]
                        }
                    },
                    {
                        "name": "encode_function_call",
                        "description": "Encode a function call with ABI",
                        "inputSchema": {
                            "type": "object",
                            "properties": {
                                "function": {
                                    "type": "string",
                                    "description": "Function name"
                                },
                                "params": {
                                    "type": "array",
                                    "description": "Function parameters"
                                }
                            },
                            "required": ["function"]
                        }
                    }
                ]
            })
        },
        "tools/call" => {
            // Handle tool calls
            let tool_name = params.get("name").and_then(|v| v.as_str()).unwrap_or("");
            let default_arguments = json!({});
            let arguments = params.get("arguments").unwrap_or(&default_arguments);
            
            match tool_name {
                "interpret_intent" => {
                    let intent = arguments.get("intent").and_then(|v| v.as_str()).unwrap_or("");
                    interpret_intent_handler(intent).await
                },
                "encode_function_call" => {
                    let function = arguments.get("function").and_then(|v| v.as_str()).unwrap_or("");
                    let default_params = json!([]);
                    let params = arguments.get("params").unwrap_or(&default_params);
                    encode_function_handler(function, params).await
                },
                _ => {
                    json!({
                        "error": format!("Unknown tool: {}", tool_name)
                    })
                }
            }
        },
        _ => {
            json!({
                "error": format!("Unknown method: {}", method)
            })
        }
    };
    
    json!({
        "jsonrpc": "2.0",
        "id": id,
        "result": result
    })
}

async fn interpret_intent_handler(intent: &str) -> Value {
    // Simple intent interpretation for now
    let result = if intent.contains("swap") || intent.contains("exchange") {
        json!({
            "protocol": "Uniswap",
            "function": "swapExactTokensForTokens",
            "confidence": 0.85
        })
    } else if intent.contains("transfer") || intent.contains("send") {
        json!({
            "protocol": "ERC20",
            "function": "transfer",
            "confidence": 0.90
        })
    } else if intent.contains("approve") {
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
    
    result
}

async fn encode_function_handler(function: &str, params: &Value) -> Value {
    // Simple encoding handler
    match function {
        "transfer" => {
            let to = params.get(0).and_then(|v| v.as_str()).unwrap_or("");
            let amount = params.get(1).and_then(|v| v.as_str()).unwrap_or("0");
            
            match crate::abi::encoder::AbiEncoder::encode_transfer(to, amount) {
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
            let spender = params.get(0).and_then(|v| v.as_str()).unwrap_or("");
            let amount = params.get(1).and_then(|v| v.as_str()).unwrap_or("0");
            
            match crate::abi::encoder::AbiEncoder::encode_approve(spender, amount) {
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
            "error": format!("Unknown function: {}", function)
        })
    }
}