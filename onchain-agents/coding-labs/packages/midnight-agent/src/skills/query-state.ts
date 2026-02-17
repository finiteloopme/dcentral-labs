/**
 * Query State Skill
 *
 * Queries public ledger state from deployed Midnight contracts
 * via the Midnight Indexer (GraphQL API).
 */

import type { Message } from '@a2a-js/sdk';
import type { SkillEvent } from './index.js';
import { extractTextFromMessage } from './index.js';
import { generateText } from 'ai';
import { model } from '../genkit.js';

// Midnight Indexer endpoints
const INDEXER_ENDPOINTS = {
  preview: 'https://indexer.preview.midnight.network/api/v3/graphql',
  preprod: 'https://indexer.preprod.midnight.network/api/v3/graphql',
};

type Network = 'preview' | 'preprod';

/**
 * Detect which network to query from the message
 */
function detectNetwork(text: string): Network {
  const lower = text.toLowerCase();
  if (lower.includes('preprod') || lower.includes('pre-prod')) {
    return 'preprod';
  }
  // Default to preview
  return 'preview';
}

/**
 * Execute a GraphQL query against the Midnight Indexer
 */
async function executeGraphQL(
  network: Network,
  query: string,
  variables?: Record<string, unknown>
): Promise<unknown> {
  const endpoint = INDEXER_ENDPOINTS[network];

  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      query,
      variables,
    }),
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

  if (result.errors) {
    throw new Error(`GraphQL errors: ${JSON.stringify(result.errors)}`);
  }

  return result.data;
}

/**
 * Generate a GraphQL query based on user request using LLM
 */
async function generateGraphQLQuery(userRequest: string): Promise<string> {
  const systemPrompt = `You are a Midnight Network expert that generates GraphQL queries for the Midnight Indexer API.

The Midnight Indexer provides a GraphQL API with the following schema (simplified):

\`\`\`graphql
type Query {
  # Get blocks
  blocks(first: Int, after: String, last: Int, before: String): BlockConnection
  block(hash: String!): Block
  
  # Get transactions
  transactions(first: Int, after: String, last: Int, before: String): TransactionConnection
  transaction(hash: String!): Transaction
  
  # Get contract state
  contractState(address: String!): ContractState
  
  # Get ledger state for a contract
  ledgerState(contractAddress: String!, key: String): LedgerEntry
}

type Block {
  hash: String!
  height: Int!
  timestamp: String!
  transactions: [Transaction!]!
}

type Transaction {
  hash: String!
  blockHash: String
  status: String!
  timestamp: String
}

type ContractState {
  address: String!
  ledger: [LedgerEntry!]!
}

type LedgerEntry {
  key: String!
  value: String!
}
\`\`\`

Based on the user's request, generate a valid GraphQL query.
Return ONLY the GraphQL query, wrapped in \`\`\`graphql code blocks.
Do not include any explanation.`;

  const response = await generateText({
    model,
    system: systemPrompt,
    prompt: userRequest,
    temperature: 0.1,
    maxOutputTokens: 1024,
  });

  const text = response.text;

  // Extract GraphQL query from response
  const match = text.match(/```graphql\n?([\s\S]*?)```/);
  if (match) {
    return match[1].trim();
  }

  // Try generic code block
  const codeMatch = text.match(/```\n?([\s\S]*?)```/);
  if (codeMatch) {
    return codeMatch[1].trim();
  }

  // Return the raw text if no code block found
  return text.trim();
}

/**
 * Query ledger state from Midnight Indexer
 */
export async function* queryState(
  message: Message
): AsyncGenerator<SkillEvent, void, unknown> {
  const userText = extractTextFromMessage(message);

  yield { type: 'status', message: 'Analyzing query request...' };

  // Detect network
  const network = detectNetwork(userText);
  yield { type: 'status', message: `Using ${network} network` };

  try {
    // Check if user provided a specific contract address
    const addressMatch = userText.match(/0x[a-fA-F0-9]{40,}/);
    const contractAddress = addressMatch ? addressMatch[0] : null;

    let query: string;
    let variables: Record<string, unknown> | undefined;

    if (contractAddress) {
      // If we have a contract address, query its state directly
      query = `
        query GetContractState($address: String!) {
          contractState(address: $address) {
            address
            ledger {
              key
              value
            }
          }
        }
      `;
      variables = { address: contractAddress };
      yield {
        type: 'status',
        message: `Querying contract ${contractAddress}...`,
      };
    } else {
      // Generate a query based on the user's request
      yield { type: 'status', message: 'Generating GraphQL query...' };
      query = await generateGraphQLQuery(userText);
    }

    // Emit the generated query as an artifact
    yield {
      type: 'artifact',
      name: 'query.graphql',
      content: query,
      mimeType: 'application/graphql',
    };

    yield { type: 'status', message: 'Executing query...' };

    // Execute the query
    const result = await executeGraphQL(network, query, variables);

    // Format result as JSON
    const resultJson = JSON.stringify(result, null, 2);

    yield {
      type: 'artifact',
      name: 'result.json',
      content: resultJson,
      mimeType: 'application/json',
    };

    yield {
      type: 'result',
      data: result,
      message: 'Query executed successfully',
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error';
    console.error('[query-state] Query failed:', errorMessage);

    yield {
      type: 'error',
      message: `Query failed: ${errorMessage}`,
    };
  }
}
