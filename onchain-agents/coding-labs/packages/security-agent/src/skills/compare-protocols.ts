/**
 * Compare Protocols Skill
 *
 * Compare the security posture and risk profiles of different
 * blockchain protocols or chains.
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
  console.warn(
    '[compare-protocols] SKILLS.md not found, using minimal context'
  );
  skillsContext = '# Protocol Comparison Framework\n\nUse standard security comparison criteria.';
}

const SYSTEM_PROMPT = `You are a blockchain security analyst specializing in comparative protocol analysis.
Your role is to objectively compare the security characteristics of different blockchain protocols.

${skillsContext}

## Comparison Instructions

Compare the security posture of the specified protocols/chains across these dimensions:

1. **Consensus & Network Security** — Consensus mechanism, validator set, finality guarantees
2. **Smart Contract Security** — Language safety, formal verification, known vulnerability classes
3. **Audit History** — Number of audits, auditor reputation, findings severity
4. **Governance & Upgradability** — Upgrade mechanisms, governance model, centralization risks
5. **Bridge & Cross-chain Security** — Bridge implementations, cross-chain risks
6. **Incident History** — Past exploits, response time, recovery actions
7. **Privacy & Confidentiality** — Privacy features, data exposure risks
8. **Developer Ecosystem** — Tooling maturity, documentation quality, security resources

## Output Format

### Security Comparison: <Protocol A> vs <Protocol B> [vs <Protocol C>]

#### Summary
Brief overview of the comparison.

#### Comparison Matrix

| Dimension | <Protocol A> | <Protocol B> | Winner |
|-----------|-------------|-------------|--------|
| Consensus Security | ... | ... | ... |
| Smart Contract Safety | ... | ... | ... |
| Audit Coverage | ... | ... | ... |
| Governance | ... | ... | ... |
| Bridge Security | ... | ... | ... |
| Incident History | ... | ... | ... |
| Privacy | ... | ... | ... |
| Developer Ecosystem | ... | ... | ... |

#### Detailed Analysis
(One section per dimension with deeper comparison)

#### Verdict
Overall security comparison summary with recommendations for different use cases.

Also produce a JSON summary:
\`\`\`json
{
  "protocols": ["<A>", "<B>"],
  "dimensions": {
    "consensusSecurity": { "<A>": <1-10>, "<B>": <1-10> },
    "smartContractSafety": { "<A>": <1-10>, "<B>": <1-10> },
    "auditCoverage": { "<A>": <1-10>, "<B>": <1-10> },
    "governance": { "<A>": <1-10>, "<B>": <1-10> },
    "bridgeSecurity": { "<A>": <1-10>, "<B>": <1-10> },
    "incidentHistory": { "<A>": <1-10>, "<B>": <1-10> },
    "privacy": { "<A>": <1-10>, "<B>": <1-10> },
    "developerEcosystem": { "<A>": <1-10>, "<B>": <1-10> }
  },
  "verdict": "<brief verdict>"
}
\`\`\`
`;

/**
 * Extract JSON block from LLM response
 */
function extractJsonBlock(text: string): string | null {
  const jsonMatch = text.match(/```json\s*\n([\s\S]*?)```/);
  if (jsonMatch) {
    return jsonMatch[1].trim();
  }
  return null;
}

/**
 * Compare security posture of different protocols
 */
export async function* compareProtocols(
  message: Message
): AsyncGenerator<SkillEvent, void, unknown> {
  const userRequest = extractTextFromMessage(message);

  yield { type: 'status', message: 'Analyzing protocol security profiles...' };

  try {
    yield {
      type: 'status',
      message: 'Generating comparative security analysis...',
    };

    const response = await generateText({
      model,
      system: SYSTEM_PROMPT,
      prompt: userRequest,
      temperature: 0.2,
      maxOutputTokens: 6144,
    });

    const comparison = response.text;

    // Emit markdown report
    yield {
      type: 'artifact',
      name: 'protocol-comparison.md',
      content: comparison,
      mimeType: 'text/markdown',
    };

    // Extract and emit JSON summary if present
    const jsonBlock = extractJsonBlock(comparison);
    if (jsonBlock) {
      yield {
        type: 'artifact',
        name: 'protocol-comparison.json',
        content: jsonBlock,
        mimeType: 'application/json',
      };
    }

    yield {
      type: 'result',
      data: comparison,
      message: 'Protocol comparison completed',
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error';
    console.error('[compare-protocols] Comparison failed:', errorMessage);
    yield {
      type: 'error',
      message: `Failed to compare protocols: ${errorMessage}`,
    };
  }
}
