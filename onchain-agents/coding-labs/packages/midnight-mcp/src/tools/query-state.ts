/**
 * query_contract_state tool
 *
 * Queries public ledger state for a deployed Midnight contract
 * via the Midnight Indexer GraphQL API (v3).
 */

import type { MidnightMCPConfig } from '../config.js';
import { getIndexerUrl, resolveNetwork } from '../config.js';

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
 */
export async function queryContractState(
  address: string,
  config: MidnightMCPConfig,
  network?: string,
  fields?: string[]
): Promise<QueryStateResult> {
  const resolvedNetwork = resolveNetwork(config, network);
  const endpoint = getIndexerUrl(config, resolvedNetwork);

  // Build field selection
  const fieldSelection =
    fields && fields.length > 0
      ? fields.join('\n          ')
      : `key
          value`;

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
