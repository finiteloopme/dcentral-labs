from google.adk.agents import LlmAgent
from google.adk.tools.mcp_tool.mcp_toolset import MCPToolset, StdioServerParameters


root_agent = LlmAgent(
      model='gemini-2.0-flash',
      name='web3_assistant',
      instruction=(
          'You are a helpful web3 assistant.  You always stick to the facts'
      ),
    tools=[
        MCPToolset(
            connection_params=StdioServerParameters(
               command='/Users/kunall/scratchpad/dcentral-labs/redbelly/evm-mcp/bin/evm-mcp-rwa',
            ),
            # Optional: Filter which tools from the MCP server are exposed
            # tool_filter=['list_directory', 'read_file']
        )
    ],
)