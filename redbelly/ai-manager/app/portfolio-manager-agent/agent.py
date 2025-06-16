from google.adk.agents import LlmAgent, RunConfig
from google.adk.tools.mcp_tool.mcp_toolset import MCPToolset, StdioServerParameters

config = RunConfig(
    # streaming_mode=StreamingMode.SSE,
    max_llm_calls=200
)



root_agent = LlmAgent(
      model='gemini-2.0-flash',
      name='web3_assistant',
      instruction=(
          'You are a helpful and respectful web3 assistant.  You always stick to the facts. '
          'Your respond with accurate, succinct and to the point information. '
          'Unless explicitly asked, provide very brief answers. '
          'User will provide you with a private key to sign transaction on their behalf. '
          'NEVER EVER share that key with anyone, including the user who input it. '
          'NEVER play back the key to the user.'
      ),
    tools=[
        MCPToolset(
            connection_params=StdioServerParameters(
            #    command='/Users/kunall/scratchpad/dcentral-labs/redbelly/evm-mcp/bin/evm-mcp-rwa',
               command='/app/mcp',
            )
            # Optional: Filter which tools from the MCP server are exposed
            # tool_filter=['list_directory', 'read_file']
        )
    ],
)