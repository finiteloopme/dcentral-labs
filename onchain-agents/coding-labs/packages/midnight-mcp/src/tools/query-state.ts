/**
 * query_contract_state tool
 *
 * Queries public ledger state for a deployed Midnight contract.
 *
 * Uses toolkit's contract-state command for direct state queries,
 * with fallback to Indexer GraphQL API for more complex queries.
 */

import type { MidnightMCPConfig } from '../config.js';
import { getIndexerUrl, getNodeRpcUrl, resolveNetwork } from '../config.js';
import { getContractState as toolkitGetState } from '../toolkit-client.js';

export interface QueryStateResult {
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
 * Query contract state by address.
 *
 * This uses the toolkit's contract-state command for direct node queries.
 * For GraphQL queries with field selection, it falls back to the Indexer API.
 *
 * @param address - Contract address
 * @param config - MCP config
 * @param network - Target network
 * @param fields - Optional GraphQL fields to select (triggers Indexer fallback)
 */
export async function queryContractState(
  address: string,
  config: MidnightMCPConfig,
  network?: string,
  fields?: string[]
): Promise<QueryStateResult> {
  const resolvedNetwork = resolveNetwork(config, network);

  // If specific fields requested, use GraphQL Indexer
  if (fields && fields.length > 0) {
    return queryContractStateViaIndexer(
      address,
      config,
      resolvedNetwork,
      fields
    );
  }

  // Use toolkit for direct state query
  try {
    const nodeRpcUrl = getNodeRpcUrl(config, resolvedNetwork);
    const result = await toolkitGetState(address, resolvedNetwork, nodeRpcUrl);

    if (!result.success) {
      return {
        success: false,
        network: resolvedNetwork,
        query: `contract-state --contract-address ${address}`,
        data: null,
        errors: result.error,
      };
    }

    return {
      success: true,
      network: resolvedNetwork,
      query: `contract-state --contract-address ${address}`,
      data: {
        contractState: {
          address,
          state: result.state,
        },
      },
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error';
    return {
      success: false,
      network: resolvedNetwork,
      query: `contract-state --contract-address ${address}`,
      data: null,
      errors: errorMessage,
    };
  }
}

/**
 * Query contract state via Indexer GraphQL API.
 * Used when specific field selection is needed.
 */
async function queryContractStateViaIndexer(
  address: string,
  config: MidnightMCPConfig,
  resolvedNetwork: string,
  fields: string[]
): Promise<QueryStateResult> {
  const endpoint = getIndexerUrl(config, resolvedNetwork);

  // Build field selection
  const fieldSelection = fields.join('\n          ');

  const query = `
    query GetContractState($address: String!) {
      contractState(address: $address) {
        address
        ledger {
          ${fieldSelection}
        }
      }
    }
  `;

  try {
    const data = await executeGraphQL(endpoint, query, { address });

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
