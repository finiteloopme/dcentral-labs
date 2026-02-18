/**
 * Solidity Code Generation Skill
 *
 * Uses LLM (Vertex AI) to generate Solidity smart contracts based on user prompts.
 */

import { streamText } from 'ai';
import type { Message } from '@a2a-js/sdk';
import type { WalletContext } from '@coding-labs/shared';
import type { SkillEvent } from './index.js';
import { extractTextFromMessage } from './index.js';
import { model, getSolidityGenSystemPrompt } from '../genkit.js';

/**
 * Generate Solidity code based on user request.
 */
export async function* generateSolidity(
  userMessage: Message,
  _walletContext?: WalletContext,
  _sessionId?: string
): AsyncGenerator<SkillEvent, void, unknown> {
  yield { type: 'status', message: 'Generating Solidity code...' };

  const userText = extractTextFromMessage(userMessage);
  const systemPrompt = getSolidityGenSystemPrompt();

  try {
    // Stream the response
    const result = await streamText({
      model,
      system: systemPrompt,
      prompt: userText,
    });

    let fullText = '';
    let lastYield = Date.now();

    // Accumulate the response
    for await (const chunk of result.textStream) {
      fullText += chunk;

      // Yield status updates every 500ms to show progress
      if (Date.now() - lastYield > 500) {
        yield { type: 'status', message: 'Generating code...' };
        lastYield = Date.now();
      }
    }

    // Extract Solidity code from the response
    const code = extractSolidityCode(fullText);

    if (!code) {
      yield {
        type: 'error',
        message:
          'Failed to generate valid Solidity code. Please try again with more details.',
      };
      return;
    }

    // Extract contract name for filename
    const contractName = extractContractName(code);
    const filename = `${contractName}.sol`;

    yield {
      type: 'artifact',
      name: filename,
      content: code,
      mimeType: 'text/x-solidity',
    };

    yield {
      type: 'result',
      data: {
        filename,
        contractName,
        linesOfCode: code.split('\n').length,
      },
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    yield {
      type: 'error',
      message: `Failed to generate Solidity code: ${errorMessage}`,
    };
  }
}

/**
 * Extract Solidity code from LLM response.
 * Handles markdown code blocks and raw Solidity.
 */
function extractSolidityCode(text: string): string | null {
  // Try to find code block
  const codeBlockMatch = text.match(/```(?:solidity)?\s*([\s\S]*?)```/);
  if (codeBlockMatch) {
    return codeBlockMatch[1].trim();
  }

  // Check if the whole response is Solidity code
  if (
    text.includes('pragma solidity') ||
    text.includes('// SPDX-License-Identifier')
  ) {
    return text.trim();
  }

  // Try to extract from SPDX to the end
  const spdxMatch = text.match(/(\/\/ SPDX-License-Identifier[\s\S]*)/);
  if (spdxMatch) {
    return spdxMatch[1].trim();
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
