use anyhow::Result;
use rmcp::{
    model::*,
    service::*,
    transport::{TokioChildProcess, ConfigureCommandExt},
};
use std::borrow::Cow;
use tokio::process::Command;
use serde_json::json;

#[tokio::main]
async fn main() -> Result<()> {
    let transport = TokioChildProcess::new(Command::new("../server/target/debug/mcp-evm-server").configure(|c| {c;}))?;

    let service = ().serve(transport).await?;

    let result = service
        .call_tool(CallToolRequestParam {
            name: Cow::Borrowed("get_token_price"),
            arguments: Some(json!({
                "token0": "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
                "token1": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
            }).as_object().unwrap().clone()),
        })
        .await?;

    println!("Result: {:?}", result);

    Ok(())
}