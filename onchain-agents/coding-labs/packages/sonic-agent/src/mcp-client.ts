/**
 * MCP Client for evm-mcp server.
 *
 * This client connects to evm-mcp via HTTP to call Foundry tools:
 * - chain_start / chain_stop
 * - forge_compile / forge_deploy
 * - cast_call / cast_send / cast_receipt
 *
 * Note: We use direct HTTP calls instead of the SSE transport for simplicity,
 * since each tool call is a single request-response.
 */

import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { SSEClientTransport } from '@modelcontextprotocol/sdk/client/sse.js';

// MCP server URL
const EVM_MCP_URL = process.env.EVM_MCP_URL || 'http://localhost:4011';

// Sonic chain configuration
export const SONIC_NETWORK = 'sonic-mainnet';
export const SONIC_CHAIN_ID = 146;

// Client singleton
let mcpClient: Client | null = null;
let transport: SSEClientTransport | null = null;

/**
 * Get or create MCP client connection.
 */
export async function getMcpClient(): Promise<Client> {
  if (mcpClient) {
    return mcpClient;
  }

  console.log(`[SonicAgent] Connecting to evm-mcp at ${EVM_MCP_URL}`);

  // Create SSE transport
  transport = new SSEClientTransport(new URL(`${EVM_MCP_URL}/sse`));

  // Create client
  mcpClient = new Client(
    {
      name: 'sonic-agent',
      version: '0.1.0',
    },
    {
      capabilities: {},
    }
  );

  // Connect
  await mcpClient.connect(transport);

  console.log('[SonicAgent] Connected to evm-mcp');

  return mcpClient;
}

/**
 * Call an MCP tool on evm-mcp.
 */
export async function callMcpTool<T = unknown>(
  toolName: string,
  args: Record<string, unknown>
): Promise<T> {
  const client = await getMcpClient();

  console.log(`[SonicAgent] Calling MCP tool: ${toolName}`);

  const result = await client.callTool({
    name: toolName,
    arguments: args,
  });

  // Parse the result from the content array
  if (
    result.content &&
    Array.isArray(result.content) &&
    result.content.length > 0
  ) {
    const firstContent = result.content[0];
    if ('text' in firstContent && typeof firstContent.text === 'string') {
      try {
        return JSON.parse(firstContent.text) as T;
      } catch {
        // Return raw text if not JSON
        return firstContent.text as T;
      }
    }
  }

  return result as T;
}

/**
 * Start the Sonic chain (Anvil fork).
 */
export async function startChain(sessionId: string): Promise<{
  success: boolean;
  chain?: { name: string; chainId: number; rpcUrl: string };
  anvil?: { rpcUrl: string; running: boolean };
  accounts?: Array<{ address: string; privateKey: string }>;
  error?: string;
}> {
  return callMcpTool('chain_start', {
    network: SONIC_NETWORK,
    sessionId,
    agentId: 'sonic-agent',
  });
}

/**
 * Stop the chain and release session.
 */
export async function stopChain(sessionId?: string): Promise<{
  success: boolean;
  stopped: boolean;
  chain: string;
  message: string;
}> {
  return callMcpTool('chain_stop', {
    sessionId,
  });
}

/**
 * Compile Solidity source code.
 */
export async function compileContract(
  source: string,
  filename?: string
): Promise<{
  success: boolean;
  contractName?: string;
  abi?: unknown[];
  bytecode?: string;
  errors?: string;
}> {
  return callMcpTool('forge_compile', {
    source,
    filename,
    solcVersion: '0.8.28',
  });
}

/**
 * Deploy a contract.
 */
export async function deployContract(
  bytecode: string,
  abi: unknown[],
  sessionId: string,
  constructorArgs?: unknown[],
  devMode = true
): Promise<{
  success: boolean;
  mode?: string;
  contractAddress?: string;
  txHash?: string;
  unsignedTx?: unknown;
  error?: string;
}> {
  return callMcpTool('forge_deploy', {
    bytecode,
    abi,
    constructorArgs,
    network: SONIC_NETWORK,
    sessionId,
    agentId: 'sonic-agent',
    devMode,
  });
}

/**
 * Call a view function on a contract.
 */
export async function callContract(
  contractAddress: string,
  functionSig: string,
  args: string[],
  sessionId: string,
  devMode = true
): Promise<{
  success: boolean;
  result?: string;
  decoded?: unknown;
  error?: string;
}> {
  return callMcpTool('cast_call', {
    contractAddress,
    functionSig,
    args,
    sessionId,
    devMode,
  });
}

/**
 * Get transaction receipt.
 */
export async function getReceipt(
  txHash: string,
  sessionId: string,
  devMode = true
): Promise<{
  success: boolean;
  status?: string;
  blockNumber?: number;
  gasUsed?: string;
  contractAddress?: string;
  logsCount?: number;
  error?: string;
}> {
  return callMcpTool('cast_receipt', {
    txHash,
    sessionId,
    devMode,
  });
}

/**
 * Get session info.
 */
export async function getSessionInfo(): Promise<{
  hasActiveSession: boolean;
  sessionId?: string;
  agentId?: string;
  chainId?: number;
  chainName?: string;
  anvilRunning?: boolean;
}> {
  return callMcpTool('session_info', {});
}

/**
 * Disconnect MCP client.
 */
export async function disconnectMcp(): Promise<void> {
  if (mcpClient) {
    await mcpClient.close();
    mcpClient = null;
    transport = null;
    console.log('[SonicAgent] Disconnected from evm-mcp');
  }
}
