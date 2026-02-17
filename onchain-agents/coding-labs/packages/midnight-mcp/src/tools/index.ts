/**
 * Tool registration for the Midnight MCP server.
 *
 * Registers all tools with the MCP server instance.
 */

import { z } from 'zod';
import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import type { MidnightMCPConfig } from '../config.js';
import { compileCompact } from './compile.js';
import { validateCompact } from './validate.js';
import { queryContractState } from './query-state.js';
import { queryBlocks } from './query-blocks.js';
import { checkProofServer, generateProof } from './prove.js';
import { requestTokens } from './faucet.js';

export function registerTools(
  server: McpServer,
  config: MidnightMCPConfig
): void {
  // --- compact_compile ---
  server.tool(
    'compact_compile',
    'Compile Compact smart contract source code to ZK circuits and JavaScript artifacts. ' +
      'Input is Compact source code (must include pragma language_version 0.20). ' +
      'Returns compiled artifacts: JS implementation, TypeScript declarations, and contract info.',
    {
      source: z
        .string()
        .describe(
          'Compact smart contract source code (must include pragma language_version directive)'
        ),
    },
    async ({ source }) => {
      const result = await compileCompact(source, config);

      if (!result.success) {
        return {
          content: [
            {
              type: 'text' as const,
              text: `Compilation failed: ${result.message}\n\n${result.errors || ''}`,
            },
          ],
          isError: true,
        };
      }

      const content: Array<{ type: 'text'; text: string }> = [
        { type: 'text' as const, text: result.message },
      ];

      for (const artifact of result.artifacts) {
        content.push({
          type: 'text' as const,
          text: `\n--- ${artifact.filename} (${artifact.mimeType}) ---\n${artifact.content}`,
        });
      }

      return { content };
    }
  );

  // --- compact_validate ---
  server.tool(
    'compact_validate',
    'Validate Compact smart contract syntax without full compilation. ' +
      'Faster than compile - checks structure, pragma, braces, and optionally runs compiler validation.',
    {
      source: z
        .string()
        .describe('Compact smart contract source code to validate'),
    },
    async ({ source }) => {
      const result = await validateCompact(source, config);

      const parts: string[] = [result.message];

      if (result.errors.length > 0) {
        parts.push('\nErrors:');
        for (const err of result.errors) {
          parts.push(`  - ${err}`);
        }
      }

      if (result.warnings.length > 0) {
        parts.push('\nWarnings:');
        for (const warn of result.warnings) {
          parts.push(`  - ${warn}`);
        }
      }

      return {
        content: [{ type: 'text' as const, text: parts.join('\n') }],
        isError: !result.valid,
      };
    }
  );

  // --- query_contract_state ---
  server.tool(
    'query_contract_state',
    'Query public ledger state for a deployed Midnight contract via the Indexer GraphQL API (v3). ' +
      "Returns the contract's public ledger entries (key-value pairs).",
    {
      address: z.string().describe('Contract address on the Midnight network'),
      network: z
        .enum(['preview', 'preprod'])
        .optional()
        .describe('Network to query (default: preview)'),
      fields: z
        .array(z.string())
        .optional()
        .describe(
          'Specific ledger fields to query (default: all key-value pairs)'
        ),
    },
    async ({ address, network, fields }) => {
      const result = await queryContractState(address, config, network, fields);

      if (!result.success) {
        return {
          content: [
            {
              type: 'text' as const,
              text: `Query failed (${result.network}): ${result.errors}`,
            },
          ],
          isError: true,
        };
      }

      return {
        content: [
          {
            type: 'text' as const,
            text: `Contract state on ${result.network}:\n\n${JSON.stringify(result.data, null, 2)}`,
          },
        ],
      };
    }
  );

  // --- query_blocks ---
  server.tool(
    'query_blocks',
    'Query block data from the Midnight ledger via the Indexer GraphQL API (v3). ' +
      'Can retrieve the latest blocks or a specific block by hash.',
    {
      network: z
        .enum(['preview', 'preprod'])
        .optional()
        .describe('Network to query (default: preview)'),
      blockHash: z
        .string()
        .optional()
        .describe('Specific block hash to query (omit for latest blocks)'),
      limit: z
        .number()
        .optional()
        .describe('Number of blocks to return (default: 10, max: 100)'),
    },
    async ({ network, blockHash, limit }) => {
      const result = await queryBlocks(config, {
        network,
        blockHash,
        limit: Math.min(limit || 10, 100),
      });

      if (!result.success) {
        return {
          content: [
            {
              type: 'text' as const,
              text: `Block query failed (${result.network}): ${result.errors}`,
            },
          ],
          isError: true,
        };
      }

      return {
        content: [
          {
            type: 'text' as const,
            text: `Blocks on ${result.network}:\n\n${JSON.stringify(result.data, null, 2)}`,
          },
        ],
      };
    }
  );

  // --- zk_prove ---
  server.tool(
    'zk_prove',
    'Interact with the Midnight Proof Server for ZK proof generation. ' +
      'Currently checks proof server availability and provides SDK guidance. ' +
      'For full proof generation, use the Midnight.js SDK with httpClientProofProvider.',
    {
      network: z
        .enum(['preview', 'preprod'])
        .optional()
        .describe('Network context (default: preview)'),
      action: z
        .enum(['health', 'prove'])
        .optional()
        .describe(
          "Action: 'health' to check server status, 'prove' to attempt proof generation (default: health)"
        ),
      circuitData: z
        .string()
        .optional()
        .describe('Base64-encoded circuit data (required for action=prove)'),
      witnessData: z
        .record(z.unknown())
        .optional()
        .describe(
          'Witness data as key-value pairs (required for action=prove)'
        ),
    },
    async ({ network, action, circuitData, witnessData }) => {
      const act = action || 'health';

      if (act === 'health') {
        const result = await checkProofServer(config, network);
        return {
          content: [
            {
              type: 'text' as const,
              text: result.success
                ? `Proof Server is reachable at ${result.proofServerUrl}`
                : `Proof Server check failed: ${result.errors}`,
            },
          ],
          isError: !result.success,
        };
      }

      // action === "prove"
      const result = await generateProof(
        circuitData || '',
        witnessData || {},
        config,
        network
      );

      return {
        content: [
          {
            type: 'text' as const,
            text: JSON.stringify(result.data, null, 2),
          },
        ],
        isError: !result.success,
      };
    }
  );

  // --- request_tokens ---
  server.tool(
    'request_tokens',
    'Request testnet tokens (tDUST) from the Midnight faucet. ' +
      'May require manual web UI interaction if the faucet API is not available programmatically.',
    {
      address: z.string().describe('Midnight wallet address to fund'),
      network: z
        .enum(['preview', 'preprod'])
        .optional()
        .describe('Network faucet to use (default: preview)'),
    },
    async ({ address, network }) => {
      const result = await requestTokens(address, config, network);

      return {
        content: [
          {
            type: 'text' as const,
            text: result.success
              ? `Token request submitted for ${address} on ${result.network}`
              : JSON.stringify(result.data, null, 2),
          },
        ],
        isError: !result.success,
      };
    }
  );
}
