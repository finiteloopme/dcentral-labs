/**
 * Explain Finding Skill
 *
 * Deep-dive explanation of a specific vulnerability type.
 * Educational content with real-world examples, attack scenarios,
 * and remediation guidance.
 */

import type { Message } from '@a2a-js/sdk';
import { readFileSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';
import { generateText } from 'ai';
import { model } from '../genkit.js';
import type { SkillEvent } from './index.js';
import { extractTextFromMessage } from './index.js';

// Load SKILLS.md as context for the LLM
const __dirname = dirname(fileURLToPath(import.meta.url));
const skillsPath = join(__dirname, '..', '..', 'SKILLS.md');

let skillsContext: string;
try {
  skillsContext = readFileSync(skillsPath, 'utf-8');
} catch {
  console.warn('[explain-finding] SKILLS.md not found, using minimal context');
  skillsContext = '# Security Vulnerability Reference\n\nUse standard vulnerability knowledge.';
}

const SYSTEM_PROMPT = `You are a blockchain security educator and researcher. Your role is to provide
detailed, educational explanations of smart contract vulnerabilities and security concepts.

${skillsContext}

## Explanation Instructions

Provide a comprehensive deep-dive explanation of the requested vulnerability or security concept.

Structure your response as follows:

### <Vulnerability Name>

#### Overview
Clear, concise explanation of what this vulnerability is.

#### How It Works
Step-by-step explanation of the attack mechanism.

#### Real-World Examples
Notable incidents where this vulnerability was exploited (with approximate dates and impact).

#### Attack Scenario
Detailed walkthrough of how an attacker would exploit this vulnerability:
1. Step 1...
2. Step 2...
3. Step 3...

#### Vulnerable Code Example
\`\`\`solidity
// or \`\`\`compact for Midnight
// Show the vulnerable pattern
\`\`\`

#### Fixed Code Example
\`\`\`solidity
// or \`\`\`compact for Midnight
// Show the secure pattern
\`\`\`

#### Prevention Checklist
- [ ] Check 1
- [ ] Check 2
- [ ] Check 3

#### References
- CWE/SWC IDs
- Relevant documentation links
- Academic papers or blog posts

Make the explanation accessible to intermediate developers while being technically precise.
Include both Solidity and Compact examples where applicable.
`;

/**
 * Provide deep-dive explanation of a vulnerability
 */
export async function* explainFinding(
  message: Message
): AsyncGenerator<SkillEvent, void, unknown> {
  const userRequest = extractTextFromMessage(message);

  yield { type: 'status', message: 'Researching vulnerability details...' };

  try {
    yield {
      type: 'status',
      message: 'Generating detailed explanation with examples...',
    };

    const response = await generateText({
      model,
      system: SYSTEM_PROMPT,
      prompt: userRequest,
      temperature: 0.2,
      maxOutputTokens: 6144,
    });

    const explanation = response.text;

    yield {
      type: 'artifact',
      name: 'finding-explanation.md',
      content: explanation,
      mimeType: 'text/markdown',
    };

    yield {
      type: 'result',
      data: explanation,
      message: 'Vulnerability explanation generated',
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error';
    console.error('[explain-finding] Explanation failed:', errorMessage);
    yield {
      type: 'error',
      message: `Failed to explain finding: ${errorMessage}`,
    };
  }
}
