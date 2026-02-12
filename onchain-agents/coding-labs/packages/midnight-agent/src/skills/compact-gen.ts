/**
 * Compact Code Generation Skill
 *
 * Generates Compact smart contracts for Midnight Network
 * using LLM with comprehensive language context from SKILLS.md.
 */

import type { Message } from '@a2a-js/sdk';
import { readFileSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';
import { ai, geminiModel } from '../genkit.js';
import type { SkillEvent } from './index.js';
import { extractTextFromMessage } from './index.js';

// Load SKILLS.md as context for the LLM
const __dirname = dirname(fileURLToPath(import.meta.url));
const skillsPath = join(__dirname, '..', '..', 'SKILLS.md');

let skillsContext: string;
try {
  skillsContext = readFileSync(skillsPath, 'utf-8');
} catch {
  console.warn('[compact-gen] SKILLS.md not found, using minimal context');
  skillsContext = `
# Compact Language Reference

Compact is Midnight's smart contract language for ZK-proof enabled contracts.

## Basic Structure
\`\`\`compact
pragma language_version 0.20;
import CompactStandardLibrary;

export ledger counter: Counter;

export circuit increment(): [] {
  counter.increment(1);
}
\`\`\`

## Key Concepts
- \`ledger\`: Public on-chain state
- \`circuit\`: ZK-provable functions
- \`witness\`: Private off-chain computations
- \`Counter\`, \`Map\`, \`Set\`, \`List\`: Ledger ADTs
`;
}

const SYSTEM_PROMPT = `You are an expert Compact smart contract developer for the Midnight Network.
Your role is to generate high-quality, secure Compact code based on user requirements.

${skillsContext}

## Response Guidelines

1. Always include \`pragma language_version 0.20;\` at the top
2. Import CompactStandardLibrary when using standard types
3. Use \`export\` for circuits and ledger fields that should be publicly accessible
4. Include clear comments explaining the contract's purpose and structure
5. Follow security best practices from the documentation
6. Use appropriate ledger ADTs (Counter, Map, Set, List, MerkleTree) for state

Respond with the complete Compact contract code wrapped in \`\`\`compact code blocks.
After the code, provide a brief explanation of:
- What the contract does
- Key circuits and their purpose
- Any security considerations
`;

/**
 * Generate Compact smart contract code
 */
export async function* generateCompact(
  message: Message
): AsyncGenerator<SkillEvent, void, unknown> {
  const userRequest = extractTextFromMessage(message);

  yield { type: 'status', message: 'Analyzing request...' };

  try {
    yield { type: 'status', message: 'Generating Compact contract...' };

    const response = await ai.generate({
      model: geminiModel,
      system: SYSTEM_PROMPT,
      prompt: userRequest,
      config: {
        temperature: 0.2, // Lower temperature for more deterministic code
        maxOutputTokens: 4096,
      },
    });

    const generatedText = response.text;

    // Extract Compact code from the response
    const compactCodeMatch = generatedText.match(/```compact\n([\s\S]*?)```/);
    const compactCode = compactCodeMatch ? compactCodeMatch[1].trim() : null;

    if (compactCode) {
      // Emit the code as an artifact
      yield {
        type: 'artifact',
        name: 'contract.compact',
        content: compactCode,
        mimeType: 'text/x-compact',
      };
    }

    yield {
      type: 'result',
      data: generatedText,
      message: 'Compact contract generated successfully',
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error';
    console.error('[compact-gen] Generation failed:', errorMessage);
    yield {
      type: 'error',
      message: `Failed to generate Compact code: ${errorMessage}`,
    };
  }
}
