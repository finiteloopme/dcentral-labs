/**
 * Compile Skill
 *
 * Compiles Solidity source code using evm-mcp (Foundry Forge).
 */

import type { Message } from '@a2a-js/sdk';
import type { WalletContext } from '@coding-labs/shared';
import type { SkillEvent } from './index.js';
import { extractTextFromMessage } from './index.js';
import { compileContract } from '../mcp-client.js';

/**
 * Compile Solidity source code.
 *
 * Expects source code in the message (either directly or as code block).
 */
export async function* compileSkill(
  userMessage: Message,
  _walletContext?: WalletContext,
  _sessionId?: string
): AsyncGenerator<SkillEvent, void, unknown> {
  yield { type: 'status', message: 'Compiling Solidity code...' };

  const userText = extractTextFromMessage(userMessage);

  // Extract Solidity code from the message
  const source = extractSolidityCode(userText);

  if (!source) {
    yield {
      type: 'error',
      message:
        'No Solidity code found in message. Please provide Solidity source code to compile.',
    };
    return;
  }

  // Extract contract name for filename
  const contractName = extractContractName(source);
  const filename = `${contractName}.sol`;

  try {
    yield { type: 'status', message: `Compiling ${filename}...` };

    const result = await compileContract(source, filename);

    if (!result.success) {
      yield {
        type: 'error',
        message: `Compilation failed: ${result.errors || 'Unknown error'}`,
      };
      return;
    }

    // Output compilation result as artifact
    yield {
      type: 'artifact',
      name: 'compilation-result.json',
      content: JSON.stringify(
        {
          success: true,
          contractName: result.contractName,
          abiLength: result.abi?.length || 0,
          bytecodeLength: result.bytecode?.length || 0,
        },
        null,
        2
      ),
      mimeType: 'application/json',
    };

    // Store ABI as separate artifact
    if (result.abi) {
      yield {
        type: 'artifact',
        name: `${contractName}.abi.json`,
        content: JSON.stringify(result.abi, null, 2),
        mimeType: 'application/json',
      };
    }

    yield {
      type: 'result',
      data: {
        success: true,
        contractName: result.contractName,
        hasAbi: !!result.abi,
        hasBytecode: !!result.bytecode,
      },
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    yield {
      type: 'error',
      message: `Compilation error: ${errorMessage}`,
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
    // Extract from SPDX to end
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
