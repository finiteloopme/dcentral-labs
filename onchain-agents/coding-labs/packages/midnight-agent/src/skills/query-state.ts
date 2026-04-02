/**
 * Query State Skill
 *
 * Queries public ledger state from deployed Midnight contracts
 * via the MCP query_contract_state tool.
 */

import type { Message } from '@a2a-js/sdk';
import type { SkillEvent, SessionContext } from './index.js';
import { extractTextFromMessage } from './index.js';
import { getMCPClient } from '../mcp-client.js';

type Network = 'preview' | 'preprod' | 'local';

/**
 * Detect which network to query from the message
 */
function detectNetwork(text: string): Network {
  const lower = text.toLowerCase();
  if (lower.includes('preprod') || lower.includes('pre-prod')) {
    return 'preprod';
  }
  if (lower.includes('preview')) {
    return 'preview';
  }
  // Default to local dev chain (pre-funded, no faucet needed)
  return 'local';
}

/**
 * Query ledger state from Midnight via MCP
 */
export async function* queryState(
  message: Message,
  session?: SessionContext
): AsyncGenerator<SkillEvent, void, unknown> {
  const userText = extractTextFromMessage(message);

  yield { type: 'status', message: 'Analyzing query request...' };

  // Detect network (prefer session, then message)
  const network = (session?.network || detectNetwork(userText)) as Network;
  yield { type: 'status', message: `Using ${network} network` };

  // Check if user provided a specific contract address
  const addressMatch = userText.match(/0x[a-fA-F0-9]{40,}/);
  const contractAddress = addressMatch
    ? addressMatch[0]
    : session?.contractAddress;

  if (!contractAddress) {
    yield {
      type: 'error',
      message:
        'No contract address found. Please provide a contract address to query ' +
        '(e.g., "query state of 0x1234...") or deploy a contract first.',
    };
    return;
  }

  yield {
    type: 'status',
    message: `Querying contract ${contractAddress}...`,
  };

  const mcp = getMCPClient();

  try {
    yield { type: 'status', message: 'Querying contract state via MCP...' };

    const result = await mcp.queryContractState(contractAddress, network);

    if (!result.success) {
      yield {
        type: 'artifact',
        name: 'query-error.txt',
        content: result.errors || result.message,
        mimeType: 'text/plain',
      };

      yield {
        type: 'error',
        message: `Query failed: ${result.message}`,
      };
      return;
    }

    // Format result as JSON
    const resultJson = JSON.stringify(result.data, null, 2);

    yield {
      type: 'artifact',
      name: 'query-result.json',
      content: resultJson,
      mimeType: 'application/json',
    };

    yield {
      type: 'result',
      data: result.data,
      message: `Contract state on ${result.network || network}:\n\n${resultJson}`,
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
