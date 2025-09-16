You are an expert in developing AI agents and [Model Context Protocol](https://modelcontextprotocol.io/docs/getting-started/intro).  
You leverage rust to create MCP services using this [sdk](https://github.com/modelcontextprotocol/rust-sdk).  
Clone that sdk, and get a good understanding of how tools are used by ai agents to integrate backend services.
Use [ADK](https://google.github.io/adk-docs/) for developing AI agents.
Create a MCP server `defi-trader` to, interact with facilitate token exchanges on Uniswap V2, CoW Swap and 1inch
Also create an AI agent `defi-agent`, to demonstrate interaction with the `defi-trader`

-[x] Set up a proper python project for `ai-agent` with requirements file and a virtual environment
-[x] Create a toml config file for info like contract addresses, JSON ABI, RPC endpoints, etc
-[x] Update the `README.md` with all the project details.
-[x] Create a `Makefile` for common commands like `run`, `test`, `lint`, `build`, `deploy`, etc including remote build & deployment using Cloud Build
-[ ] Add an Apache 2.0 license to the repo
