/**
 * Call Skill
 *
 * Calls view/pure functions on deployed contracts using evm-mcp.
 */

import type { Message } from '@a2a-js/sdk';
import type { WalletContext } from '@coding-labs/shared';
import type { SkillEvent } from './index.js';
import { extractTextFromMessage } from './index.js';
import { callContract, getSessionInfo } from '../mcp-client.js';

/**
 * Call a view function on a contract.
 *
 * Extracts contract address, function signature, and arguments from the message.
 */
export async function* callSkill(
  userMessage: Message,
  _walletContext?: WalletContext,
  sessionId?: string
): AsyncGenerator<SkillEvent, void, unknown> {
  if (!sessionId) {
    yield {
      type: 'error',
      message: 'Session ID is required for contract calls.',
    };
    return;
  }

  const userText = extractTextFromMessage(userMessage);

  yield { type: 'status', message: 'Parsing contract call...' };

  // Check if chain is started
  const session = await getSessionInfo();
  if (!session.hasActiveSession) {
    yield {
      type: 'error',
      message:
        'No active chain session. Please deploy a contract first to start the chain.',
    };
    return;
  }

  // Extract contract address
  const addressMatch = userText.match(/0x[a-fA-F0-9]{40}/);
  if (!addressMatch) {
    yield {
      type: 'error',
      message:
        'No contract address found. Please provide a valid contract address (0x...).',
    };
    return;
  }
  const contractAddress = addressMatch[0];

  // Try to extract function signature
  const { functionSig, args } = extractFunctionCall(userText);

  if (!functionSig) {
    yield {
      type: 'error',
      message:
        'Could not determine function to call. Please specify the function, e.g., "call totalSupply() on 0x..."',
    };
    return;
  }

  yield {
    type: 'status',
    message: `Calling ${functionSig} on ${contractAddress.slice(0, 10)}...`,
  };

  try {
    const result = await callContract(
      contractAddress,
      functionSig,
      args,
      sessionId,
      true // devMode
    );

    if (!result.success) {
      yield {
        type: 'error',
        message: `Call failed: ${result.error}`,
      };
      return;
    }

    yield {
      type: 'artifact',
      name: 'call-result.json',
      content: JSON.stringify(
        {
          contractAddress,
          function: functionSig,
          args,
          result: result.result,
          decoded: result.decoded,
        },
        null,
        2
      ),
      mimeType: 'application/json',
    };

    yield {
      type: 'result',
      data: {
        contractAddress,
        function: functionSig,
        result: result.decoded || result.result,
      },
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    yield {
      type: 'error',
      message: `Call error: ${errorMessage}`,
    };
  }
}

/**
 * Extract function signature and arguments from user text.
 */
function extractFunctionCall(text: string): {
  functionSig: string | null;
  args: string[];
} {
  const lowerText = text.toLowerCase();

  // Common function patterns
  const patterns: Array<{ keywords: string[]; sig: string }> = [
    { keywords: ['total supply', 'totalsupply'], sig: 'totalSupply()' },
    { keywords: ['balance of', 'balanceof'], sig: 'balanceOf(address)' },
    { keywords: ['owner'], sig: 'owner()' },
    { keywords: ['name'], sig: 'name()' },
    { keywords: ['symbol'], sig: 'symbol()' },
    { keywords: ['decimals'], sig: 'decimals()' },
  ];

  for (const pattern of patterns) {
    if (pattern.keywords.some((kw) => lowerText.includes(kw))) {
      // Extract address argument if needed
      if (pattern.sig.includes('address')) {
        const addresses = text.match(/0x[a-fA-F0-9]{40}/g) || [];
        // Use second address if available (first is contract address)
        const argAddress = addresses.length > 1 ? addresses[1] : addresses[0];
        return {
          functionSig: pattern.sig,
          args: argAddress ? [argAddress] : [],
        };
      }
      return { functionSig: pattern.sig, args: [] };
    }
  }

  // Try to extract function name directly
  const funcMatch = text.match(/call\s+(\w+)\s*\(/i);
  if (funcMatch) {
    const funcName = funcMatch[1];
    // Extract args from parentheses
    const argsMatch = text.match(/\(\s*([^)]*)\s*\)/);
    const argsStr = argsMatch ? argsMatch[1] : '';
    const args = argsStr
      ? argsStr
          .split(',')
          .map((a) => a.trim())
          .filter(Boolean)
      : [];
    return { functionSig: `${funcName}()`, args };
  }

  return { functionSig: null, args: [] };
}
