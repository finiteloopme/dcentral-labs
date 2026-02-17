import type { Message } from '@a2a-js/sdk';
import type { WalletContext } from '@coding-labs/shared';
import { streamText } from 'ai';
import { model } from '../genkit.js';
import { extractTextFromMessage, type SkillEvent } from './index.js';
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

/**
 * Load SKILLS.md as context for the LLM
 */
function loadSkillsContext(): string {
  try {
    const skillsPath = join(__dirname, '../../SKILLS.md');
    return readFileSync(skillsPath, 'utf-8');
  } catch {
    // Fallback if file not found (e.g., in production build)
    return '';
  }
}

/**
 * System prompt for Solidity generation
 */
const SYSTEM_PROMPT = `You are an expert Solidity developer specializing in the Somnia blockchain.

${loadSkillsContext()}

## Your Task
Generate high-quality, secure, and gas-optimized Solidity smart contracts based on user requirements.

## Output Format
You MUST respond with a JSON object containing an array of files:
{
  "files": [
    {
      "filename": "ContractName.sol",
      "content": "// SPDX-License-Identifier: MIT\\npragma solidity ^0.8.28;\\n..."
    }
  ],
  "explanation": "Brief explanation of the generated code"
}

## Code Requirements
1. Use Solidity ^0.8.28
2. Include SPDX license identifier (MIT unless specified)
3. Import OpenZeppelin contracts where appropriate (use @openzeppelin/contracts/...)
4. Follow Somnia gas optimization guidelines:
   - Minimize event emissions (LOG operations cost 8,320+ gas on Somnia)
   - Optimize storage access patterns
   - Keep contract bytecode small (3,125 gas/byte deployment)
5. Include NatSpec comments for public functions
6. Implement proper access control
7. Use Checks-Effects-Interactions pattern
8. Include ReentrancyGuard for functions that transfer value

## Security Best Practices
- Always validate inputs
- Use SafeMath (built into Solidity 0.8+)
- Implement proper access control (Ownable, AccessControl)
- Avoid tx.origin for authentication
- Be careful with external calls
`;

/**
 * Result from Solidity generation
 */
export interface SolidityGenResult {
  files: Array<{
    filename: string;
    content: string;
  }>;
  explanation?: string;
}

/**
 * Generate Solidity contracts based on user request
 */
export async function* generateSolidity(
  userMessage: Message,
  _walletContext?: WalletContext
): AsyncGenerator<SkillEvent, void, unknown> {
  const userText = extractTextFromMessage(userMessage);

  if (!userText.trim()) {
    yield {
      type: 'error',
      message:
        'No input provided. Please describe the contract you want to generate.',
    };
    return;
  }

  yield { type: 'status', message: 'Analyzing requirements...' };

  try {
    // Generate code using AI SDK streaming
    const streamResult = streamText({
      model,
      system: SYSTEM_PROMPT,
      prompt: userText,
    });

    yield { type: 'status', message: 'Generating Solidity code...' };

    // Collect the streamed response
    let fullOutput = '';
    for await (const delta of streamResult.textStream) {
      fullOutput += delta;
    }

    // Parse the final response
    let result: SolidityGenResult;

    try {
      // Try to parse the collected output as JSON
      result = JSON.parse(fullOutput);
      if (!result?.files) {
        throw new Error('Missing files array');
      }
    } catch {
      // If JSON parsing fails, wrap raw output as a single file
      yield {
        type: 'error',
        message: 'Failed to parse generated code. Raw output returned.',
      };
      result = {
        files: [
          {
            filename: 'Contract.sol',
            content: fullOutput,
          },
        ],
      };
    }

    // Emit each file as an artifact
    for (const file of result.files) {
      yield {
        type: 'artifact',
        name: file.filename,
        content: file.content,
        mimeType: 'text/x-solidity',
      };
    }

    // Emit the final result
    yield {
      type: 'result',
      data: {
        filesGenerated: result.files.map((f) => f.filename),
        explanation: result.explanation,
      },
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error occurred';
    yield { type: 'error', message: `Code generation failed: ${errorMessage}` };
  }
}
