/**
 * Tool registration for the EVM MCP server.
 *
 * Registers all Foundry tools with the MCP server instance.
 */

import { z } from 'zod';
import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import type { EvmMcpConfig, ChainConfig } from '../config.js';
import { CHAIN_PRESETS, getChainPreset, ANVIL_ACCOUNTS } from '../config.js';
import {
  acquireSession,
  getSession,
  releaseSession,
  getSessionInfo,
} from '../session.js';
import { startAnvil } from '../foundry/anvil.js';
import { forgeCompile, forgeDeploy } from '../foundry/forge.js';
import { castCall, castSend, castReceipt } from '../foundry/cast.js';

// -----------------------------------------------------------------------------
// Schema Definitions
// -----------------------------------------------------------------------------

const chainConfigSchema = z.object({
  rpcUrl: z.string().describe('RPC URL for the chain'),
  chainId: z.number().describe('Chain ID'),
  name: z.string().optional().describe('Chain name'),
  explorerUrl: z.string().optional().describe('Block explorer URL'),
});

const networkSchema = z
  .string()
  .optional()
  .describe(
    'Network preset (sonic-mainnet, somnia-testnet, ethereum-sepolia) or "local" for Anvil. ' +
      'Defaults to local Anvil fork.'
  );

// -----------------------------------------------------------------------------
// Helper Functions
// -----------------------------------------------------------------------------

/**
 * Resolve network to chain config.
 * Defaults to local Anvil if not specified.
 */
function resolveChainConfig(
  network?: string,
  customConfig?: z.infer<typeof chainConfigSchema>
): ChainConfig {
  // If custom config provided, use it
  if (customConfig) {
    return {
      name: customConfig.name || `Chain ${customConfig.chainId}`,
      chainId: customConfig.chainId,
      rpcUrl: customConfig.rpcUrl,
      explorerUrl: customConfig.explorerUrl || '',
      nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
    };
  }

  // If network preset specified, use it
  if (network && network !== 'local') {
    const preset = getChainPreset(network);
    if (!preset) {
      throw new Error(
        `Unknown network preset: ${network}. ` +
          `Available: ${Object.keys(CHAIN_PRESETS).join(', ')}`
      );
    }
    return preset;
  }

  // Check if we have an active session with a chain
  const session = getSession();
  if (session) {
    return session.chainConfig;
  }

  throw new Error(
    'No chain specified and no active session. ' +
      'Provide a network preset or start a session with a specific chain.'
  );
}

// -----------------------------------------------------------------------------
// Tool Registration
// -----------------------------------------------------------------------------

export function registerTools(server: McpServer, config: EvmMcpConfig): void {
  // --- forge_compile ---
  server.tool(
    'forge_compile',
    'Compile Solidity source code using Foundry Forge. ' +
      'Returns ABI, bytecode, and contract metadata.',
    {
      source: z.string().describe('Solidity source code'),
      filename: z
        .string()
        .optional()
        .describe('Contract filename (default: Contract.sol)'),
      solcVersion: z
        .string()
        .optional()
        .describe(`Solidity version (default: ${config.defaultSolcVersion})`),
    },
    async ({ source, filename, solcVersion }) => {
      const result = await forgeCompile(source, config, {
        filename,
        solcVersion,
      });

      if (!result.success) {
        return {
          content: [
            {
              type: 'text' as const,
              text: `Compilation failed: ${result.errors}`,
            },
          ],
          isError: true,
        };
      }

      return {
        content: [
          {
            type: 'text' as const,
            text: JSON.stringify(
              {
                success: true,
                contractName: result.contractName,
                solcVersion: result.solcVersion,
                abi: result.abi,
                bytecode: result.bytecode,
                deployedBytecode: result.deployedBytecode,
              },
              null,
              2
            ),
          },
        ],
      };
    }
  );

  // --- forge_deploy ---
  server.tool(
    'forge_deploy',
    'Deploy a compiled contract. ' +
      'By default, deploys to local Anvil fork (dev mode). ' +
      'Set devMode=false to get unsigned transaction for mainnet deployment.',
    {
      bytecode: z.string().describe('Contract bytecode (hex)'),
      abi: z.array(z.unknown()).describe('Contract ABI'),
      constructorArgs: z
        .array(z.unknown())
        .optional()
        .describe('Constructor arguments'),
      network: networkSchema,
      chainConfig: chainConfigSchema.optional(),
      sessionId: z.string().describe('Session ID for tracking'),
      agentId: z.string().describe('Agent ID (e.g., sonic-agent)'),
      devMode: z
        .boolean()
        .optional()
        .default(true)
        .describe('Use Anvil test account (default: true)'),
    },
    async ({
      bytecode,
      abi,
      constructorArgs,
      network,
      chainConfig: customConfig,
      sessionId,
      agentId,
      devMode,
    }) => {
      try {
        const chainConfig = resolveChainConfig(network, customConfig);

        // Acquire session
        const session = acquireSession(
          sessionId,
          agentId,
          chainConfig,
          config.anvilPort
        );

        // If dev mode, ensure Anvil is running
        if (devMode) {
          if (!session.anvilProcess) {
            const anvilResult = await startAnvil(chainConfig, config.anvilPort);
            if (!anvilResult.success) {
              return {
                content: [
                  {
                    type: 'text' as const,
                    text: `Failed to start Anvil: ${anvilResult.error}`,
                  },
                ],
                isError: true,
              };
            }
          }
        }

        const rpcUrl = devMode ? session.anvilRpcUrl : chainConfig.rpcUrl;
        const privateKey = devMode ? ANVIL_ACCOUNTS[0].privateKey : undefined;

        const result = await forgeDeploy(bytecode, abi, {
          rpcUrl,
          chainId: chainConfig.chainId,
          constructorArgs,
          devMode,
          privateKey,
        });

        if (!result.success) {
          return {
            content: [
              {
                type: 'text' as const,
                text: `Deployment failed: ${result.error}`,
              },
            ],
            isError: true,
          };
        }

        if (result.unsignedTx) {
          return {
            content: [
              {
                type: 'text' as const,
                text: JSON.stringify(
                  {
                    success: true,
                    mode: 'unsigned',
                    chain: chainConfig.name,
                    chainId: chainConfig.chainId,
                    unsignedTx: result.unsignedTx,
                    instructions:
                      'Sign this transaction with your wallet and broadcast to the network.',
                  },
                  null,
                  2
                ),
              },
            ],
          };
        }

        return {
          content: [
            {
              type: 'text' as const,
              text: JSON.stringify(
                {
                  success: true,
                  mode: 'dev',
                  chain: chainConfig.name,
                  chainId: chainConfig.chainId,
                  contractAddress: result.contractAddress,
                  txHash: result.txHash,
                  rpcUrl: rpcUrl,
                },
                null,
                2
              ),
            },
          ],
        };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        return {
          content: [{ type: 'text' as const, text: `Error: ${errorMessage}` }],
          isError: true,
        };
      }
    }
  );

  // --- cast_call ---
  server.tool(
    'cast_call',
    'Call a view/pure function on a contract. ' +
      'Uses local Anvil by default, or remote RPC if devMode=false.',
    {
      contractAddress: z.string().describe('Contract address'),
      functionSig: z
        .string()
        .describe('Function signature (e.g., "balanceOf(address)")'),
      args: z.array(z.string()).optional().describe('Function arguments'),
      network: networkSchema,
      sessionId: z.string().describe('Session ID'),
      devMode: z.boolean().optional().default(true).describe('Use local Anvil'),
    },
    async ({
      contractAddress,
      functionSig,
      args,
      network: _network,
      sessionId: _sessionId,
      devMode,
    }) => {
      // Note: network and sessionId are kept for API consistency but currently
      // we use the active session state
      void _network;
      void _sessionId;

      try {
        const session = getSession();
        if (!session) {
          return {
            content: [
              {
                type: 'text' as const,
                text: 'No active session. Start a session by deploying a contract first.',
              },
            ],
            isError: true,
          };
        }

        const rpcUrl = devMode
          ? session.anvilRpcUrl
          : session.chainConfig.rpcUrl;
        const result = await castCall(
          contractAddress,
          functionSig,
          args || [],
          rpcUrl
        );

        if (!result.success) {
          return {
            content: [
              {
                type: 'text' as const,
                text: `Call failed: ${result.error}`,
              },
            ],
            isError: true,
          };
        }

        return {
          content: [
            {
              type: 'text' as const,
              text: JSON.stringify(
                {
                  success: true,
                  result: result.result,
                  decoded: result.decoded,
                },
                null,
                2
              ),
            },
          ],
        };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        return {
          content: [{ type: 'text' as const, text: `Error: ${errorMessage}` }],
          isError: true,
        };
      }
    }
  );

  // --- cast_send ---
  server.tool(
    'cast_send',
    'Send a transaction to a contract. ' +
      'In dev mode, executes immediately with test account. ' +
      'Otherwise returns unsigned transaction.',
    {
      contractAddress: z.string().describe('Contract address'),
      functionSig: z
        .string()
        .describe('Function signature (e.g., "transfer(address,uint256)")'),
      args: z.array(z.string()).optional().describe('Function arguments'),
      value: z.string().optional().describe('ETH value to send (in wei)'),
      network: networkSchema,
      sessionId: z.string().describe('Session ID'),
      devMode: z
        .boolean()
        .optional()
        .default(true)
        .describe('Use test account'),
    },
    async ({
      contractAddress,
      functionSig,
      args,
      value,
      network: _network,
      sessionId: _sessionId,
      devMode,
    }) => {
      // Note: network and sessionId are kept for API consistency but currently
      // we use the active session state
      void _network;
      void _sessionId;

      try {
        const session = getSession();
        if (!session) {
          return {
            content: [
              {
                type: 'text' as const,
                text: 'No active session. Start a session by deploying a contract first.',
              },
            ],
            isError: true,
          };
        }

        const rpcUrl = devMode
          ? session.anvilRpcUrl
          : session.chainConfig.rpcUrl;
        const privateKey = devMode ? ANVIL_ACCOUNTS[0].privateKey : undefined;

        const result = await castSend(
          contractAddress,
          functionSig,
          args || [],
          {
            rpcUrl,
            chainId: session.chainConfig.chainId,
            value,
            devMode,
            privateKey,
          }
        );

        if (!result.success) {
          return {
            content: [
              {
                type: 'text' as const,
                text: `Transaction failed: ${result.error}`,
              },
            ],
            isError: true,
          };
        }

        if (result.unsignedTx) {
          return {
            content: [
              {
                type: 'text' as const,
                text: JSON.stringify(
                  {
                    success: true,
                    mode: 'unsigned',
                    unsignedTx: result.unsignedTx,
                  },
                  null,
                  2
                ),
              },
            ],
          };
        }

        return {
          content: [
            {
              type: 'text' as const,
              text: JSON.stringify(
                {
                  success: true,
                  mode: 'dev',
                  txHash: result.txHash,
                },
                null,
                2
              ),
            },
          ],
        };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        return {
          content: [{ type: 'text' as const, text: `Error: ${errorMessage}` }],
          isError: true,
        };
      }
    }
  );

  // --- cast_receipt ---
  server.tool(
    'cast_receipt',
    'Get transaction receipt (status, gas used, logs, contract address).',
    {
      txHash: z.string().describe('Transaction hash'),
      sessionId: z.string().describe('Session ID'),
      devMode: z.boolean().optional().default(true).describe('Use local Anvil'),
    },
    async ({ txHash, sessionId: _sessionId, devMode }) => {
      // Note: sessionId is kept for API consistency but currently
      // we use the active session state
      void _sessionId;

      try {
        const session = getSession();
        if (!session) {
          return {
            content: [
              {
                type: 'text' as const,
                text: 'No active session.',
              },
            ],
            isError: true,
          };
        }

        const rpcUrl = devMode
          ? session.anvilRpcUrl
          : session.chainConfig.rpcUrl;
        const result = await castReceipt(txHash, rpcUrl);

        if (!result.success) {
          return {
            content: [
              {
                type: 'text' as const,
                text: `Failed to get receipt: ${result.error}`,
              },
            ],
            isError: true,
          };
        }

        return {
          content: [
            {
              type: 'text' as const,
              text: JSON.stringify(
                {
                  success: true,
                  status: result.status,
                  blockNumber: result.blockNumber,
                  gasUsed: result.gasUsed,
                  contractAddress: result.contractAddress,
                  logsCount: result.logs?.length || 0,
                },
                null,
                2
              ),
            },
          ],
        };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        return {
          content: [{ type: 'text' as const, text: `Error: ${errorMessage}` }],
          isError: true,
        };
      }
    }
  );

  // --- session_info ---
  server.tool(
    'session_info',
    'Get current session information (active chain, Anvil status, etc.).',
    {},
    async () => {
      const info = getSessionInfo();

      return {
        content: [
          {
            type: 'text' as const,
            text: JSON.stringify(info, null, 2),
          },
        ],
      };
    }
  );

  // --- session_release ---
  server.tool(
    'session_release',
    'Release the current session and stop Anvil.',
    {
      sessionId: z.string().optional().describe('Session ID to release'),
    },
    async ({ sessionId }) => {
      releaseSession(sessionId);

      return {
        content: [
          {
            type: 'text' as const,
            text: 'Session released.',
          },
        ],
      };
    }
  );
}
