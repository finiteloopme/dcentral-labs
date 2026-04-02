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
import { generateText } from 'ai';
import { model } from '../genkit.js';
import type { SkillEvent, Artifact } from './index.js';
import { extractTextFromMessage } from './index.js';

/**
 * Extract a meaningful contract name from Compact source code.
 * Looks for the first `export ledger` or `export circuit` declaration.
 */
function extractContractName(source: string): string {
  // Try to find a meaningful name from the ledger declarations
  const ledgerMatch = source.match(/export\s+ledger\s+(\w+)/);
  if (ledgerMatch) return ledgerMatch[1];

  // Try circuit name
  const circuitMatch = source.match(/export\s+circuit\s+(\w+)/);
  if (circuitMatch) return circuitMatch[1];

  return 'contract';
}

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

    const response = await generateText({
      model,
      system: SYSTEM_PROMPT,
      prompt: userRequest,
      temperature: 0.2, // Lower temperature for more deterministic code
      maxOutputTokens: 4096,
    });

    const generatedText = response.text;

    // Extract Compact code from the response
    // Try multiple fence formats: ```compact, ```Compact, ``` compact, plain ```
    let compactCode: string | null = null;

    const fencePatterns = [
      /```[Cc]ompact\s*\n([\s\S]*?)```/, // ```compact or ```Compact
      /```\s*\n([\s\S]*?)```/, // plain ``` code block
    ];

    for (const pattern of fencePatterns) {
      const match = generatedText.match(pattern);
      if (match) {
        compactCode = match[1].trim();
        break;
      }
    }

    // Fallback: if no code fence found but response contains pragma, extract raw code
    if (!compactCode && generatedText.includes('pragma language_version')) {
      const pragmaStart = generatedText.indexOf('pragma language_version');
      // Find the last closing brace after the pragma
      const remaining = generatedText.slice(pragmaStart);
      const lastBrace = remaining.lastIndexOf('}');
      if (lastBrace > 0) {
        compactCode = remaining.slice(0, lastBrace + 1).trim();
      } else {
        compactCode = remaining.trim();
      }
    }

    if (compactCode) {
      // Emit the code as an artifact
      yield {
        type: 'artifact',
        name: 'contract.compact',
        content: compactCode,
        mimeType: 'text/x-compact',
      };

      // Store in session for compile skill to use
      // This enables "compile" command without re-sending the code
      const contractName = extractContractName(compactCode);
      const artifact: Artifact = {
        filename: 'contract.compact',
        content: compactCode,
      };
      yield {
        type: 'session-update',
        context: {
          artifacts: [artifact],
          contractName,
        },
      };
      console.log(
        `[compact-gen] Stored contract "${contractName}" in session for compilation`
      );
    }

    // Add workflow hint to guide user to next step
    const workflowHint = `

---
**Next step:** Say "compile" or "yes" to compile this contract, or describe any changes you'd like.`;

    yield {
      type: 'result',
      data: generatedText + workflowHint,
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
