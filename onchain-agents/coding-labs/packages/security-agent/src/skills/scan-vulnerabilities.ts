/**
 * Scan Vulnerabilities Skill
 *
 * Quick targeted vulnerability scan for known patterns in smart contract code.
 * Faster and less comprehensive than a full audit — focuses on pattern matching.
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
    '[scan-vulnerabilities] SKILLS.md not found, using minimal context'
  );
  skillsContext = '# Security Vulnerability Patterns\n\nUse standard vulnerability taxonomies.';
}

const SYSTEM_PROMPT = `You are a smart contract vulnerability scanner. Your job is to quickly scan
contract code for known vulnerability patterns and produce a concise checklist report.

${skillsContext}

## Scan Instructions

Perform a QUICK, TARGETED scan of the provided code. Focus on:
1. Pattern matching against known vulnerability signatures
2. Common anti-patterns and dangerous function usage
3. Missing security checks and guards

Do NOT perform a full audit. Focus on speed and coverage of known patterns.

## Output Format

Produce a checklist-style vulnerability scan report:

### Vulnerability Scan Results

**Contract**: <name or description>
**Language**: <Solidity/Compact>
**Scan Date**: <current date>

#### Checklist

| # | Check | Status | Severity | Notes |
|---|-------|--------|----------|-------|
| 1 | Reentrancy guards | ✅ PASS / ⚠️ WARN / ❌ FAIL | - | - |
| 2 | Integer overflow protection | ✅ / ⚠️ / ❌ | - | - |
| ... | ... | ... | ... | ... |

#### Flagged Issues (if any)
Brief description of each flagged item.

#### Quick Recommendations
Top 3-5 actionable recommendations.

Keep the response concise and actionable.
`;

/**
 * Perform quick vulnerability scan of smart contract code
 */
export async function* scanVulnerabilities(
  message: Message
): AsyncGenerator<SkillEvent, void, unknown> {
  const userRequest = extractTextFromMessage(message);

  yield { type: 'status', message: 'Scanning for vulnerability patterns...' };

  try {
    yield {
      type: 'status',
      message: 'Running pattern-based vulnerability checks...',
    };

    const response = await generateText({
      model,
      system: SYSTEM_PROMPT,
      prompt: userRequest,
      temperature: 0.1,
      maxOutputTokens: 4096,
    });

    const scanReport = response.text;

    yield {
      type: 'artifact',
      name: 'vulnerability-scan.md',
      content: scanReport,
      mimeType: 'text/markdown',
    };

    yield {
      type: 'result',
      data: scanReport,
      message: 'Vulnerability scan completed',
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error';
    console.error('[scan-vulnerabilities] Scan failed:', errorMessage);
    yield {
      type: 'error',
      message: `Failed to scan for vulnerabilities: ${errorMessage}`,
    };
  }
}
