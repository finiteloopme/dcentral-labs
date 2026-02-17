/**
 * query_blocks tool
 *
 * Queries block data from the Midnight ledger via the Indexer GraphQL API (v3).
 */

import type { MidnightMCPConfig } from '../config.js';
import { getIndexerUrl, resolveNetwork } from '../config.js';

export interface QueryBlocksResult {
  success: boolean;
  network: string;
  query: string;
  data: unknown;
  errors?: string;
}

/**
 * Execute a GraphQL query against the Midnight Indexer.
 */
async function executeGraphQL(
  endpoint: string,
  query: string,
  variables?: Record<string, unknown>
): Promise<unknown> {
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ query, variables }),
  });

  if (!response.ok) {
    throw new Error(
      `GraphQL request failed: ${response.status} ${response.statusText}`
    );
  }

  const result = (await response.json()) as {
    data?: unknown;
    errors?: Array<{ message: string }>;
  };

  if (result.errors && result.errors.length > 0) {
    throw new Error(
      `GraphQL errors: ${result.errors.map((e) => e.message).join('; ')}`
    );
  }

  return result.data;
}

/**
 * Query blocks from the Midnight Indexer.
 */
export async function queryBlocks(
  config: MidnightMCPConfig,
  options: {
    network?: string;
    blockHash?: string;
    limit?: number;
  } = {}
): Promise<QueryBlocksResult> {
  const resolvedNetwork = resolveNetwork(config, options.network);
  const endpoint = getIndexerUrl(config, resolvedNetwork);
  const limit = options.limit || 10;

  let query: string;
  let variables: Record<string, unknown> | undefined;

  if (options.blockHash) {
    // Query specific block by hash
    query = `
      query GetBlock($hash: String!) {
        block(hash: $hash) {
          hash
          height
          timestamp
          transactions {
            hash
            status
            timestamp
          }
        }
      }
    `;
    variables = { hash: options.blockHash };
  } else {
    // Query latest blocks
    query = `
      query GetBlocks($first: Int) {
        blocks(first: $first) {
          edges {
            node {
              hash
              height
              timestamp
              transactions {
                hash
                status
              }
            }
          }
          pageInfo {
            hasNextPage
            endCursor
          }
        }
      }
    `;
    variables = { first: limit };
  }

  try {
    const data = await executeGraphQL(endpoint, query, variables);
    return {
      success: true,
      network: resolvedNetwork,
      query,
      data,
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error';
    return {
      success: false,
      network: resolvedNetwork,
      query,
      data: null,
      errors: errorMessage,
    };
  }
}
