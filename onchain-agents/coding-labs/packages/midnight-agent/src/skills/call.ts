/**
 * Call Circuit Skill
 *
 * Executes a circuit (function) on a deployed Midnight contract.
 * Uses MCP tools via HTTP for wallet creation and circuit execution.
 *
 * Prerequisites:
 *   1. Contract must be deployed (contractAddress from session or message)
 *   2. Compiled artifacts must be available (artifacts from session)
 *   3. Wallet is created automatically via MCP
 */

import type { Message } from '@a2a-js/sdk';
import type { SkillEvent, SessionContext } from './index.js';
import { extractTextFromMessage } from './index.js';
import { getMCPClient } from '../mcp-client.js';

/**
 * Extract contract address from text (0x-prefixed hex string).
 */
function extractContractAddress(text: string): string | null {
  const match = text.match(/0x[a-fA-F0-9]{40,}/);
  return match ? match[0] : null;
}

/**
 * Extract circuit name from user message.
 * Looks for patterns like "call increment", "execute the transfer circuit", etc.
 */
function extractCircuitName(text: string): string | null {
  const patterns = [
    /(?:call|execute|run|invoke)\s+(?:the\s+)?["']?(\w+)["']?\s*(?:circuit|function)?/i,
    /circuit\s+["']?(\w+)["']?/i,
    /function\s+["']?(\w+)["']?/i,
  ];

  for (const pattern of patterns) {
    const match = text.match(pattern);
    if (match) {
      return match[1];
    }
  }

  return null;
}

/**
 * Extract arguments from user message.
 * Looks for patterns like "with args [1, 2, 3]" or "arguments: {value: 100}".
 */
function extractArguments(text: string): unknown[] | null {
  // Try to find array arguments
  const arrayMatch = text.match(
    /(?:args?|arguments?|params?)\s*[=:]\s*\[([^\]]+)\]/i
  );
  if (arrayMatch) {
    try {
      return JSON.parse(`[${arrayMatch[1]}]`);
    } catch {
      // Not valid JSON, skip
    }
  }

  // Try to find a single numeric argument
  const numMatch = text.match(/(?:with|value|amount)\s*[=:]\s*(\d+)/i);
  if (numMatch) {
    return [parseInt(numMatch[1], 10)];
  }

  return null;
}

/**
 * Extract contract name from user message.
 */
function extractContractName(text: string): string | null {
  const nameMatch = text.match(/contract\s+["']?(\w+)["']?/i);
  return nameMatch ? nameMatch[1] : null;
}

/**
 * Detect target network from user message.
 */
function detectNetwork(text: string): 'preview' | 'preprod' | 'local' {
  const lower = text.toLowerCase();
  if (lower.includes('preprod')) return 'preprod';
  if (lower.includes('preview')) return 'preview';
  // Default to local dev chain (pre-funded, no faucet needed)
  return 'local';
}

/**
 * Execute a circuit on a deployed Midnight contract via MCP.
 */
export async function* callCircuitSkill(
  message: Message,
  session?: SessionContext
): AsyncGenerator<SkillEvent, void, unknown> {
  const userText = extractTextFromMessage(message);

  yield { type: 'status', message: 'Analyzing circuit call request...' };

  // 1. Extract contract address - required
  const contractAddress =
    session?.contractAddress || extractContractAddress(userText);

  if (!contractAddress) {
    yield {
      type: 'error',
      message:
        'No contract address found. Please deploy a contract first or provide the address ' +
        '(e.g., "call increment on 0x1234...").',
    };
    return;
  }

  yield { type: 'status', message: `Contract: ${contractAddress}` };

  // 2. Extract circuit name - required
  const circuitName = extractCircuitName(userText);

  if (!circuitName) {
    yield {
      type: 'error',
      message:
        'No circuit name found. Please specify which circuit to call ' +
        '(e.g., "call the increment circuit").',
    };
    return;
  }

  yield { type: 'status', message: `Circuit: ${circuitName}` };

  // 3. Get artifacts - required for circuit execution
  const artifacts = session?.artifacts;

  if (!artifacts || artifacts.length === 0) {
    yield {
      type: 'error',
      message:
        'No compiled artifacts found. The compiled contract artifacts are required ' +
        'for circuit execution. Please compile and deploy the contract in this session.',
    };
    return;
  }

  // 4. Get contract name
  const contractName =
    session?.contractName || extractContractName(userText) || 'contract';

  // 5. Determine target network
  const network = (session?.network || detectNetwork(userText)) as
    | 'preview'
    | 'preprod'
    | 'local';

  yield { type: 'status', message: `Network: ${network}` };

  // 6. Extract optional arguments
  const args = extractArguments(userText);
  if (args) {
    yield { type: 'status', message: `Arguments: ${JSON.stringify(args)}` };
  }

  const mcp = getMCPClient();

  // 7. Create wallet (required for circuit calls)
  yield {
    type: 'status',
    message: 'Creating wallet for transaction via MCP...',
  };

  try {
    const walletResult = await mcp.createWallet(network);

    if (!walletResult.success) {
      yield {
        type: 'error',
        message: `Wallet creation failed: ${walletResult.message}`,
      };
      return;
    }

    yield {
      type: 'status',
      message: `Wallet ready: ${walletResult.address}`,
    };

    // 8. Execute the circuit via MCP
    yield {
      type: 'status',
      message: `Executing circuit "${circuitName}" via MCP...`,
    };

    const result = await mcp.callContract(
      contractAddress,
      circuitName,
      artifacts,
      contractName,
      network,
      args || undefined
    );

    if (!result.success) {
      yield {
        type: 'artifact',
        name: 'call-error.json',
        content: JSON.stringify(result, null, 2),
        mimeType: 'application/json',
      };

      yield {
        type: 'error',
        message: result.message,
      };
      return;
    }

    // 9. Emit call result as artifact
    yield {
      type: 'artifact',
      name: 'call-result.json',
      content: JSON.stringify(
        {
          success: true,
          network: result.network,
          contractAddress: result.contractAddress,
          circuitName: result.circuitName,
          txId: result.txId,
          txHash: result.txHash,
          blockHeight: result.blockHeight,
          explorerUrl: `https://explorer.${result.network}.midnight.network/tx/${result.txId}`,
        },
        null,
        2
      ),
      mimeType: 'application/json',
    };

    yield {
      type: 'result',
      data: result,
      message:
        `Circuit "${circuitName}" executed successfully!\n\n` +
        `Network: ${result.network}\n` +
        `Contract: ${result.contractAddress}\n` +
        `Transaction: ${result.txId}\n` +
        `Block: ${result.blockHeight}`,
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error';

    yield {
      type: 'artifact',
      name: 'call-error.txt',
      content: errorMessage,
      mimeType: 'text/plain',
    };

    yield {
      type: 'error',
      message: `Circuit call failed: ${errorMessage}`,
    };
  }
}
