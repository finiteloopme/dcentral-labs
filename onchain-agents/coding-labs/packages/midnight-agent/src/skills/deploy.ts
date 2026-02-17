/**
 * Deploy Contract Skill
 *
 * Deploys a compiled Compact contract to Midnight Network.
 * Uses MCP tools via HTTP for wallet creation and deployment.
 *
 * Prerequisites:
 *   1. Contract must be compiled (artifacts from session)
 *   2. Wallet is created automatically via MCP
 *   3. Network can be specified (defaults to preview)
 */

import type { Message } from '@a2a-js/sdk';
import type { SkillEvent, SessionContext, Artifact } from './index.js';
import { extractTextFromMessage } from './index.js';
import { getMCPClient } from '../mcp-client.js';

// Auto-funding configuration (fixed defaults)
const MIN_BALANCE_TDUST = 10;
const FUNDING_WAIT_MS = 30000; // 30 seconds to wait for faucet
const BALANCE_CHECK_INTERVAL_MS = 5000; // Check every 5 seconds

/** MCP client type for helper functions */
type MCPClient = ReturnType<typeof getMCPClient>;

/**
 * Extract artifacts embedded in a message (from prior compile step).
 * Returns array of {filename, content} pairs.
 */
function extractEmbeddedArtifacts(message: Message): Artifact[] {
  const artifacts: Artifact[] = [];

  for (const part of message.parts) {
    // Check for file artifacts in A2A format
    if ('kind' in part && part.kind === 'file') {
      const filePart = part as { kind: 'file'; name?: string; data?: string };
      if (filePart.name && filePart.data) {
        artifacts.push({ filename: filePart.name, content: filePart.data });
      }
    }

    // Check for text parts that might contain JSON artifacts
    if ('kind' in part && part.kind === 'text') {
      const textPart = part as { kind: 'text'; text?: string };
      if (textPart.text) {
        // Look for contract-info.json content
        const jsonMatch = textPart.text.match(/```json\n([\s\S]*?)```/);
        if (jsonMatch) {
          try {
            JSON.parse(jsonMatch[1]); // Validate it's JSON
            artifacts.push({
              filename: 'contract-info.json',
              content: jsonMatch[1],
            });
          } catch {
            // Not valid JSON, skip
          }
        }
      }
    }
  }

  return artifacts;
}

/**
 * Detect target network from user message.
 */
function detectNetwork(text: string): 'preview' | 'preprod' | 'local' {
  const lower = text.toLowerCase();
  if (lower.includes('preprod')) return 'preprod';
  if (lower.includes('local') || lower.includes('standalone')) return 'local';
  return 'preview';
}

/**
 * Extract contract name from user message.
 */
function extractContractName(text: string): string | null {
  const nameMatch = text.match(/contract\s+["']?(\w+)["']?/i);
  return nameMatch ? nameMatch[1] : null;
}

/**
 * Wait for wallet to be funded above minimum balance.
 * Polls the wallet balance at intervals until funded or timeout.
 */
async function waitForFunding(
  mcp: MCPClient,
  network: string,
  minBalance: number
): Promise<{ funded: boolean; balance: string }> {
  const maxAttempts = Math.ceil(FUNDING_WAIT_MS / BALANCE_CHECK_INTERVAL_MS);

  for (let i = 0; i < maxAttempts; i++) {
    await new Promise((r) => setTimeout(r, BALANCE_CHECK_INTERVAL_MS));
    const walletResult = await mcp.createWallet(network);

    if (walletResult.success) {
      const balance = parseFloat(walletResult.balance || '0');
      if (balance >= minBalance) {
        return { funded: true, balance: walletResult.balance || '0' };
      }
    }
  }

  return { funded: false, balance: '0' };
}

/**
 * Deploy a Compact contract to Midnight Network via MCP.
 */
export async function* deployContractSkill(
  message: Message,
  session?: SessionContext
): AsyncGenerator<SkillEvent, void, unknown> {
  const userText = extractTextFromMessage(message);

  yield { type: 'status', message: 'Analyzing deployment request...' };

  // 1. Determine target network
  const network = (session?.network || detectNetwork(userText)) as
    | 'preview'
    | 'preprod'
    | 'local';
  yield { type: 'status', message: `Target network: ${network}` };

  // 2. Get artifacts - try session first, then message
  let artifacts = session?.artifacts;
  let contractName =
    session?.contractName || extractContractName(userText) || 'contract';

  if (!artifacts || artifacts.length === 0) {
    yield {
      type: 'status',
      message: 'No artifacts in session, checking for embedded artifacts...',
    };

    artifacts = extractEmbeddedArtifacts(message);
  }

  if (!artifacts || artifacts.length === 0) {
    yield {
      type: 'error',
      message:
        'No compiled artifacts found. Please compile the contract first using the compile skill.',
    };
    return;
  }

  yield {
    type: 'status',
    message: `Found ${artifacts.length} artifact(s) for deployment`,
  };
  yield { type: 'status', message: `Contract name: ${contractName}` };

  const mcp = getMCPClient();

  // 3. Create wallet (required for deployment)
  yield {
    type: 'status',
    message: 'Creating wallet for deployment via MCP...',
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
      message: `Wallet ready: ${walletResult.address} (${walletResult.balance} tDUST)`,
    };

    // 4. Check balance and auto-fund if needed (testnets only)
    const balance = parseFloat(walletResult.balance || '0');

    if (network !== 'local' && balance < MIN_BALANCE_TDUST) {
      yield {
        type: 'status',
        message: `Wallet balance (${balance} tDUST) is below minimum (${MIN_BALANCE_TDUST}). Requesting tokens from faucet...`,
      };

      const faucetResult = await mcp.requestTokens(
        walletResult.address!,
        network
      );

      if (faucetResult.manualRequired) {
        const faucetUrl =
          faucetResult.faucetUrl ||
          `https://faucet.${network}.midnight.network/`;

        yield {
          type: 'artifact',
          name: 'funding-instructions.json',
          content: JSON.stringify(
            {
              status: 'manual_funding_required',
              network,
              address: walletResult.address,
              faucetUrl,
              instructions: [
                `1. Open ${faucetUrl} in a browser`,
                `2. Paste address: ${walletResult.address}`,
                '3. Complete any captcha verification',
                "4. Click 'Request tDUST'",
                '5. Re-run deployment after funding completes',
              ],
            },
            null,
            2
          ),
          mimeType: 'application/json',
        };

        yield {
          type: 'error',
          message:
            `Automatic faucet funding not available.\n\n` +
            `Please fund your wallet manually:\n` +
            `1. Visit the faucet at ${faucetUrl}\n` +
            `2. Paste address: ${walletResult.address}\n` +
            `3. Request tDUST tokens\n` +
            `4. Re-run deployment after funding completes`,
        };
        return;
      }

      if (!faucetResult.success) {
        yield {
          type: 'error',
          message: `Faucet request failed: ${faucetResult.message}`,
        };
        return;
      }

      yield {
        type: 'status',
        message: 'Faucet request submitted. Waiting for tokens to arrive...',
      };

      const fundingResult = await waitForFunding(
        mcp,
        network,
        MIN_BALANCE_TDUST
      );

      if (!fundingResult.funded) {
        yield {
          type: 'error',
          message:
            `Timeout waiting for faucet funding.\n` +
            `Please check wallet balance manually and re-try deployment.\n` +
            `Address: ${walletResult.address}`,
        };
        return;
      }

      yield {
        type: 'status',
        message: `Wallet funded: ${fundingResult.balance} tDUST`,
      };
    }

    // 5. Deploy the contract via MCP
    yield {
      type: 'status',
      message: 'Deploying contract to Midnight Network via MCP...',
    };

    const result = await mcp.deployContract(artifacts, contractName, network);

    if (!result.success) {
      yield {
        type: 'artifact',
        name: 'deploy-error.json',
        content: JSON.stringify(result, null, 2),
        mimeType: 'application/json',
      };

      yield {
        type: 'error',
        message: result.message,
      };
      return;
    }

    // 6. Update session with deployed contract info
    yield {
      type: 'session-update',
      context: {
        contractAddress: result.contractAddress,
        network: result.network,
      },
    };

    // 7. Emit deployment result as artifact
    yield {
      type: 'artifact',
      name: 'deployment-result.json',
      content: JSON.stringify(
        {
          success: true,
          network: result.network,
          contractAddress: result.contractAddress,
          txId: result.txId,
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
        `Contract "${contractName}" deployed successfully!\n\n` +
        `Network: ${result.network}\n` +
        `Address: ${result.contractAddress}\n` +
        `Transaction: ${result.txId}\n` +
        `Block: ${result.blockHeight}`,
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error';

    yield {
      type: 'artifact',
      name: 'deploy-error.txt',
      content: errorMessage,
      mimeType: 'text/plain',
    };

    yield {
      type: 'error',
      message: `Deployment failed: ${errorMessage}`,
    };
  }
}
