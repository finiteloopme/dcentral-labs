/**
 * Deploy Skill
 *
 * Deploys contracts to Sonic chain using evm-mcp.
 * - Dev mode (default): Deploys to local Anvil fork
 * - Mainnet mode: Returns unsigned transaction for user to sign
 */

import type { Message } from '@a2a-js/sdk';
import type { WalletContext } from '@coding-labs/shared';
import type { SkillEvent } from './index.js';
import { extractTextFromMessage } from './index.js';
import { startChain, compileContract, deployContract } from '../mcp-client.js';

/**
 * Deploy a contract to Sonic.
 *
 * If source code is provided, compiles first then deploys.
 * If bytecode is provided directly, deploys it.
 */
export async function* deploySkill(
  userMessage: Message,
  walletContext?: WalletContext,
  sessionId?: string
): AsyncGenerator<SkillEvent, void, unknown> {
  if (!sessionId) {
    yield { type: 'error', message: 'Session ID is required for deployment.' };
    return;
  }

  const userText = extractTextFromMessage(userMessage);

  // Check if user wants mainnet deployment
  const wantsMainnet =
    userText.toLowerCase().includes('mainnet') ||
    userText.toLowerCase().includes('production');

  // For mainnet, we need wallet context
  if (wantsMainnet && !walletContext?.connected) {
    yield {
      type: 'error',
      message:
        'Wallet must be connected for mainnet deployment. Please connect your wallet first.',
    };
    return;
  }

  yield { type: 'status', message: 'Starting Sonic chain fork...' };

  try {
    // 1. Start chain (Anvil fork)
    const chainResult = await startChain(sessionId);
    if (!chainResult.success) {
      yield {
        type: 'error',
        message: `Failed to start chain: ${chainResult.error}`,
      };
      return;
    }

    yield {
      type: 'status',
      message: `Connected to ${chainResult.chain?.name || 'Sonic'}`,
    };

    // 2. Extract and compile source code
    const source = extractSolidityCode(userText);
    if (!source) {
      yield {
        type: 'error',
        message:
          'No Solidity code found. Please provide contract source code to deploy.',
      };
      return;
    }

    const contractName = extractContractName(source);
    const filename = `${contractName}.sol`;

    yield { type: 'status', message: `Compiling ${filename}...` };

    const compileResult = await compileContract(source, filename);
    if (!compileResult.success) {
      yield {
        type: 'error',
        message: `Compilation failed: ${compileResult.errors}`,
      };
      return;
    }

    yield { type: 'status', message: 'Compilation successful. Deploying...' };

    // 3. Deploy
    const devMode = !wantsMainnet;
    const deployResult = await deployContract(
      compileResult.bytecode!,
      compileResult.abi!,
      sessionId,
      undefined, // constructor args
      devMode
    );

    if (!deployResult.success) {
      yield {
        type: 'error',
        message: `Deployment failed: ${deployResult.error}`,
      };
      return;
    }

    // 4. Return result
    if (deployResult.unsignedTx) {
      // Mainnet mode - return unsigned tx
      yield {
        type: 'artifact',
        name: 'unsigned-transaction.json',
        content: JSON.stringify(deployResult.unsignedTx, null, 2),
        mimeType: 'application/json',
      };

      yield {
        type: 'result',
        data: {
          mode: 'mainnet',
          message:
            'Contract compiled. Sign the transaction with your wallet to deploy to Sonic mainnet.',
          unsignedTx: deployResult.unsignedTx,
        },
      };
    } else {
      // Dev mode - contract deployed to Anvil
      yield {
        type: 'artifact',
        name: 'deployment-result.json',
        content: JSON.stringify(
          {
            contractAddress: deployResult.contractAddress,
            txHash: deployResult.txHash,
            contractName,
            chain: 'Sonic (Anvil Fork)',
          },
          null,
          2
        ),
        mimeType: 'application/json',
      };

      yield {
        type: 'result',
        data: {
          mode: 'dev',
          contractAddress: deployResult.contractAddress,
          txHash: deployResult.txHash,
          contractName,
          message: `Contract ${contractName} deployed to local Anvil fork at ${deployResult.contractAddress}`,
        },
      };
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    yield {
      type: 'error',
      message: `Deployment error: ${errorMessage}`,
    };
  }
}

/**
 * Extract Solidity code from text.
 */
function extractSolidityCode(text: string): string | null {
  // Try to find code block
  const codeBlockMatch = text.match(/```(?:solidity)?\s*([\s\S]*?)```/);
  if (codeBlockMatch) {
    return codeBlockMatch[1].trim();
  }

  // Check if the text contains Solidity code
  if (
    text.includes('pragma solidity') ||
    text.includes('// SPDX-License-Identifier')
  ) {
    const spdxMatch = text.match(/(\/\/ SPDX-License-Identifier[\s\S]*)/);
    if (spdxMatch) {
      return spdxMatch[1].trim();
    }
    return text.trim();
  }

  return null;
}

/**
 * Extract contract name from Solidity code.
 */
function extractContractName(code: string): string {
  const match = code.match(/contract\s+(\w+)/);
  return match ? match[1] : 'Contract';
}
