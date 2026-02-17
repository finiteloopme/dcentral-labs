/**
 * MCP Client for Midnight Agent
 *
 * Connects to the midnight-mcp server via HTTP/SSE and calls tools.
 * This replaces direct function imports with HTTP-based tool calls.
 */

import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { SSEClientTransport } from '@modelcontextprotocol/sdk/client/sse.js';

/**
 * Artifact structure for passing compiled contract files.
 */
export interface Artifact {
  filename: string;
  content: string;
}

/**
 * Result from an MCP tool call.
 */
export interface MCPToolResult {
  success: boolean;
  content: string;
  isError?: boolean;
  raw?: unknown;
}

/**
 * Parsed result from compact_compile tool.
 */
export interface CompileResult {
  success: boolean;
  message: string;
  compiledDir?: string;
  artifacts: Artifact[];
  errors?: string;
}

/**
 * Parsed result from wallet_create tool.
 */
export interface WalletResult {
  success: boolean;
  message: string;
  network?: string;
  address?: string;
  balance?: string;
  seed?: string;
  errors?: string;
}

/**
 * Parsed result from contract_deploy tool.
 */
export interface DeployResult {
  success: boolean;
  message: string;
  network?: string;
  contractAddress?: string;
  txId?: string;
  blockHeight?: string;
  errors?: string;
}

/**
 * Parsed result from contract_call tool.
 */
export interface CallResult {
  success: boolean;
  message: string;
  network?: string;
  contractAddress?: string;
  circuitName?: string;
  txId?: string;
  txHash?: string;
  blockHeight?: string;
  errors?: string;
}

/**
 * Parsed result from query_contract_state tool.
 */
export interface QueryStateResult {
  success: boolean;
  message: string;
  network?: string;
  data?: unknown;
  errors?: string;
}

/**
 * Parsed result from request_tokens tool.
 */
export interface FaucetResult {
  success: boolean;
  message: string;
  network?: string;
  faucetUrl?: string;
  manualRequired?: boolean;
  errors?: string;
}

/**
 * MCP Client for communicating with midnight-mcp server.
 */
class MidnightMCPClient {
  private client: Client;
  private transport: SSEClientTransport | null = null;
  private connected = false;
  private mcpUrl: string;

  constructor(mcpUrl: string) {
    this.mcpUrl = mcpUrl;
    this.client = new Client({
      name: 'midnight-agent',
      version: '0.1.0',
    });
  }

  /**
   * Connect to the MCP server.
   */
  async connect(): Promise<void> {
    if (this.connected) {
      return;
    }

    try {
      const sseUrl = new URL('/sse', this.mcpUrl);
      this.transport = new SSEClientTransport(sseUrl);
      await this.client.connect(this.transport);
      this.connected = true;
      console.log(`[mcp-client] Connected to ${this.mcpUrl}`);
    } catch (error) {
      console.error('[mcp-client] Failed to connect:', error);
      throw error;
    }
  }

  /**
   * Close the connection.
   */
  async close(): Promise<void> {
    if (this.transport) {
      await this.transport.close();
      this.connected = false;
      this.transport = null;
    }
  }

  /**
   * Call an MCP tool and return the result.
   */
  async callTool(
    name: string,
    args: Record<string, unknown>
  ): Promise<MCPToolResult> {
    await this.connect();

    try {
      const result = await this.client.callTool({ name, arguments: args });

      // Extract text content from MCP response
      const content = (result.content as Array<{ type: string; text?: string }>)
        .filter((c) => c.type === 'text')
        .map((c) => c.text || '')
        .join('\n');

      const isError = Boolean(result.isError);
      return {
        success: !isError,
        content,
        isError,
        raw: result,
      };
    } catch (error) {
      const message =
        error instanceof Error ? error.message : 'Unknown MCP error';
      return {
        success: false,
        content: message,
        isError: true,
      };
    }
  }

  /**
   * Compile Compact source code.
   */
  async compileCompact(source: string): Promise<CompileResult> {
    const result = await this.callTool('compact_compile', { source });

    if (!result.success) {
      return {
        success: false,
        message: result.content,
        artifacts: [],
        errors: result.content,
      };
    }

    // Parse artifacts from response
    const artifacts: Artifact[] = [];
    const artifactMatches = result.content.matchAll(
      /--- ([^\s]+) \(([^)]+)\) ---\n([\s\S]*?)(?=\n--- |$)/g
    );
    for (const match of artifactMatches) {
      artifacts.push({
        filename: match[1],
        content: match[3].trim(),
      });
    }

    // Extract compiledDir from response
    const dirMatch = result.content.match(/Compiled directory: ([^\n]+)/);
    const compiledDir = dirMatch ? dirMatch[1].trim() : undefined;

    return {
      success: true,
      message: result.content.split('\n')[0] || 'Compilation successful',
      compiledDir,
      artifacts,
    };
  }

  /**
   * Create or retrieve a wallet.
   */
  async createWallet(network?: string): Promise<WalletResult> {
    const result = await this.callTool('wallet_create', { network });

    if (!result.success) {
      return {
        success: false,
        message: result.content,
        errors: result.content,
      };
    }

    // Parse wallet info from response
    const networkMatch = result.content.match(/Network: ([^\n]+)/);
    const addressMatch = result.content.match(/Address: ([^\n]+)/);
    const balanceMatch = result.content.match(/Balance: ([^\n]+)/);
    const seedMatch = result.content.match(/Seed: ([^\n]+)/);

    return {
      success: true,
      message: result.content.split('\n')[0] || 'Wallet created',
      network: networkMatch ? networkMatch[1].trim() : undefined,
      address: addressMatch ? addressMatch[1].trim() : undefined,
      balance: balanceMatch ? balanceMatch[1].trim() : undefined,
      seed: seedMatch ? seedMatch[1].trim() : undefined,
    };
  }

  /**
   * Deploy a compiled contract.
   */
  async deployContract(
    artifacts: Artifact[],
    contractName: string,
    network?: string,
    initialPrivateState?: Record<string, unknown>
  ): Promise<DeployResult> {
    const result = await this.callTool('contract_deploy', {
      artifacts,
      contractName,
      network,
      initialPrivateState,
    });

    if (!result.success) {
      return {
        success: false,
        message: result.content,
        errors: result.content,
      };
    }

    // Parse deployment info from response
    const networkMatch = result.content.match(/Network: ([^\n]+)/);
    const addressMatch = result.content.match(/Contract Address: ([^\n]+)/);
    const txIdMatch = result.content.match(/Transaction ID: ([^\n]+)/);
    const blockMatch = result.content.match(/Block Height: ([^\n]+)/);

    return {
      success: true,
      message: result.content.split('\n')[0] || 'Deployment successful',
      network: networkMatch ? networkMatch[1].trim() : undefined,
      contractAddress: addressMatch ? addressMatch[1].trim() : undefined,
      txId: txIdMatch ? txIdMatch[1].trim() : undefined,
      blockHeight: blockMatch ? blockMatch[1].trim() : undefined,
    };
  }

  /**
   * Call a circuit on a deployed contract.
   */
  async callContract(
    contractAddress: string,
    circuitName: string,
    artifacts: Artifact[],
    contractName: string,
    network?: string,
    args?: unknown[]
  ): Promise<CallResult> {
    const result = await this.callTool('contract_call', {
      contractAddress,
      circuitName,
      artifacts,
      contractName,
      network,
      args,
    });

    if (!result.success) {
      return {
        success: false,
        message: result.content,
        errors: result.content,
      };
    }

    // Parse call info from response
    const networkMatch = result.content.match(/Network: ([^\n]+)/);
    const addressMatch = result.content.match(/Contract: ([^\n]+)/);
    const circuitMatch = result.content.match(/Circuit: ([^\n]+)/);
    const txIdMatch = result.content.match(/Transaction ID: ([^\n]+)/);
    const txHashMatch = result.content.match(/Transaction Hash: ([^\n]+)/);
    const blockMatch = result.content.match(/Block Height: ([^\n]+)/);

    return {
      success: true,
      message: result.content.split('\n')[0] || 'Call successful',
      network: networkMatch ? networkMatch[1].trim() : undefined,
      contractAddress: addressMatch ? addressMatch[1].trim() : undefined,
      circuitName: circuitMatch ? circuitMatch[1].trim() : undefined,
      txId: txIdMatch ? txIdMatch[1].trim() : undefined,
      txHash: txHashMatch ? txHashMatch[1].trim() : undefined,
      blockHeight: blockMatch ? blockMatch[1].trim() : undefined,
    };
  }

  /**
   * Query contract state.
   */
  async queryContractState(
    address: string,
    network?: string,
    fields?: string[]
  ): Promise<QueryStateResult> {
    const result = await this.callTool('query_contract_state', {
      address,
      network,
      fields,
    });

    if (!result.success) {
      return {
        success: false,
        message: result.content,
        errors: result.content,
      };
    }

    // Try to parse JSON data from response
    const jsonMatch = result.content.match(/\{[\s\S]*\}/);
    let data: unknown;
    if (jsonMatch) {
      try {
        data = JSON.parse(jsonMatch[0]);
      } catch {
        data = result.content;
      }
    }

    // Extract network
    const networkMatch = result.content.match(/on (\w+):/);

    return {
      success: true,
      message: 'Query successful',
      network: networkMatch ? networkMatch[1] : undefined,
      data,
    };
  }

  /**
   * Request testnet tokens from the Midnight faucet.
   */
  async requestTokens(
    address: string,
    network?: string
  ): Promise<FaucetResult> {
    const result = await this.callTool('request_tokens', { address, network });

    if (!result.success) {
      // Check if manual faucet interaction is needed
      const isManualRequired =
        result.content.includes('manual_required') ||
        result.content.includes('web UI') ||
        result.content.includes('manual interaction');

      // Try to extract faucet URL from response
      const faucetUrlMatch = result.content.match(/https?:\/\/faucet\.[^\s"]+/);

      return {
        success: false,
        message: result.content,
        faucetUrl: faucetUrlMatch ? faucetUrlMatch[0] : undefined,
        manualRequired: isManualRequired,
        errors: result.content,
      };
    }

    // Extract network from response
    const networkMatch = result.content.match(/on (\w+)/);

    return {
      success: true,
      message: result.content,
      network: networkMatch ? networkMatch[1] : undefined,
    };
  }
}

// Singleton instance
let mcpClient: MidnightMCPClient | null = null;

/**
 * Get the singleton MCP client instance.
 * Uses MIDNIGHT_MCP_URL environment variable, defaults to http://localhost:4010.
 */
export function getMCPClient(): MidnightMCPClient {
  if (!mcpClient) {
    const mcpUrl = process.env.MIDNIGHT_MCP_URL || 'http://localhost:4010';
    mcpClient = new MidnightMCPClient(mcpUrl);
  }
  return mcpClient;
}

/**
 * Close the MCP client connection.
 */
export async function closeMCPClient(): Promise<void> {
  if (mcpClient) {
    await mcpClient.close();
    mcpClient = null;
  }
}
