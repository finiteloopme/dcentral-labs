/**
 * Transaction Status Skill
 *
 * Checks the status of a transaction using evm-mcp.
 */

import type { Message } from '@a2a-js/sdk';
import type { WalletContext } from '@coding-labs/shared';
import type { SkillEvent } from './index.js';
import { extractTextFromMessage } from './index.js';
import { getReceipt, getSessionInfo } from '../mcp-client.js';

/**
 * Check the status of a transaction.
 */
export async function* txStatusSkill(
  userMessage: Message,
  _walletContext?: WalletContext,
  sessionId?: string
): AsyncGenerator<SkillEvent, void, unknown> {
  if (!sessionId) {
    yield { type: 'error', message: 'Session ID is required.' };
    return;
  }

  const userText = extractTextFromMessage(userMessage);

  yield { type: 'status', message: 'Looking up transaction...' };

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

  // Extract transaction hash
  const txHashMatch = userText.match(/0x[a-fA-F0-9]{64}/);
  if (!txHashMatch) {
    yield {
      type: 'error',
      message:
        'No transaction hash found. Please provide a valid transaction hash (0x... 64 hex chars).',
    };
    return;
  }
  const txHash = txHashMatch[0];

  yield {
    type: 'status',
    message: `Fetching receipt for ${txHash.slice(0, 18)}...`,
  };

  try {
    const result = await getReceipt(txHash, sessionId, true);

    if (!result.success) {
      yield {
        type: 'error',
        message: `Failed to get receipt: ${result.error}`,
      };
      return;
    }

    const statusText =
      result.status === '0x1' || result.status === 'success'
        ? 'Success'
        : result.status === '0x0' || result.status === 'failed'
          ? 'Failed'
          : result.status || 'Unknown';

    yield {
      type: 'artifact',
      name: 'transaction-receipt.json',
      content: JSON.stringify(
        {
          txHash,
          status: statusText,
          blockNumber: result.blockNumber,
          gasUsed: result.gasUsed,
          contractAddress: result.contractAddress,
          logsCount: result.logsCount,
        },
        null,
        2
      ),
      mimeType: 'application/json',
    };

    // Build human-readable summary
    let summary = `Transaction ${txHash.slice(0, 18)}...\n\n`;
    summary += `**Status**: ${statusText}\n`;
    summary += `**Block**: ${result.blockNumber || 'Pending'}\n`;
    summary += `**Gas Used**: ${result.gasUsed || 'N/A'}\n`;

    if (result.contractAddress) {
      summary += `**Contract Created**: ${result.contractAddress}\n`;
    }

    if (result.logsCount && result.logsCount > 0) {
      summary += `**Events Emitted**: ${result.logsCount}\n`;
    }

    yield {
      type: 'result',
      data: {
        txHash,
        status: statusText,
        blockNumber: result.blockNumber,
        gasUsed: result.gasUsed,
        contractAddress: result.contractAddress,
        summary,
      },
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    yield {
      type: 'error',
      message: `Error fetching transaction: ${errorMessage}`,
    };
  }
}
