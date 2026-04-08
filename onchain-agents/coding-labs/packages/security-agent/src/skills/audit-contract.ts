/**
 * Audit Contract Skill
 *
 * Performs comprehensive security audits of Solidity or Compact smart contracts.
 * Uses LLM with security knowledge base from SKILLS.md for analysis.
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
  console.warn('[audit-contract] SKILLS.md not found, using minimal context');
  skillsContext = `
# Security Audit Reference

## Solidity Vulnerabilities
- Reentrancy, integer overflow/underflow, access control issues
- Delegatecall risks, front-running, flash loan attacks

## Compact/Midnight Vulnerabilities
- Witness validation failures, disclosure leaks, proof soundness issues

## Severity Levels
- Critical: Direct loss of funds
- High: Significant impact on functionality
- Medium: Moderate impact, requires specific conditions
- Low: Minor issues, best practice violations
- Informational: Code quality suggestions
`;
}

/**
 * Detect contract language from source code
 */
function detectLanguage(code: string): 'solidity' | 'compact' | 'unknown' {
  if (code.includes('pragma solidity') || code.includes('contract ') || code.includes('function ')) {
    return 'solidity';
  }
  if (code.includes('pragma language_version') || code.includes('export ledger') || code.includes('export circuit')) {
    return 'compact';
  }
  return 'unknown';
}

/**
 * Build system prompt for the audit
 */
function buildSystemPrompt(language: string): string {
  return `You are an expert smart contract security auditor specializing in blockchain security.
Your role is to perform comprehensive security audits of smart contract code.

${skillsContext}

## Audit Instructions

You are auditing a ${language === 'compact' ? 'Compact (Midnight Network)' : language === 'solidity' ? 'Solidity (EVM)' : ''} smart contract.

Perform a thorough security audit covering:
1. **Vulnerability Detection**: Identify all security vulnerabilities using the taxonomy above
2. **Severity Classification**: Rate each finding as Critical, High, Medium, Low, or Informational
3. **Impact Analysis**: Explain the potential impact of each vulnerability
4. **Remediation**: Provide specific code fixes for each finding
5. **Best Practices**: Note any deviations from security best practices

## Output Format

Structure your response as a security audit report with:

### Executive Summary
Brief overview of the audit scope, methodology, and key findings.

### Findings
For each finding:
- **[SEVERITY] Title**
- **Description**: What the vulnerability is
- **Location**: Where in the code (function/line reference)
- **Impact**: What could happen if exploited
- **Recommendation**: How to fix it with code example
- **References**: CWE/SWC IDs where applicable

### Summary Table
| # | Severity | Title | Status |
|---|----------|-------|--------|

### Overall Assessment
Final security rating and recommendations.

Also produce a JSON summary of findings in this format:
\`\`\`json
{
  "contract": "<name>",
  "language": "<solidity|compact>",
  "overallRisk": "<critical|high|medium|low|informational>",
  "findings": [
    {
      "id": "F-001",
      "severity": "<critical|high|medium|low|informational>",
      "title": "<title>",
      "description": "<description>",
      "location": "<function or line>",
      "impact": "<impact>",
      "recommendation": "<fix>",
      "cwe": "<CWE-ID if applicable>"
    }
  ],
  "summary": {
    "critical": 0,
    "high": 0,
    "medium": 0,
    "low": 0,
    "informational": 0,
    "total": 0
  }
}
\`\`\`
`;
}

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
 * Perform comprehensive security audit of a smart contract
 */
export async function* auditContract(
  message: Message
): AsyncGenerator<SkillEvent, void, unknown> {
  const userRequest = extractTextFromMessage(message);

  yield { type: 'status', message: 'Analyzing contract code...' };

  try {
    // Detect contract language
    const language = detectLanguage(userRequest);
    const languageLabel =
      language === 'solidity'
        ? 'Solidity'
        : language === 'compact'
          ? 'Compact'
          : 'smart contract';

    yield {
      type: 'status',
      message: `Detected ${languageLabel} contract. Performing security audit...`,
    };

    const systemPrompt = buildSystemPrompt(language);

    const response = await generateText({
      model,
      system: systemPrompt,
      prompt: userRequest,
      temperature: 0.1, // Low temperature for precise, deterministic analysis
      maxOutputTokens: 8192,
    });

    const auditReport = response.text;

    // Emit the full audit report as a markdown artifact
    yield {
      type: 'artifact',
      name: 'audit-report.md',
      content: auditReport,
      mimeType: 'text/markdown',
    };

    // Extract and emit JSON findings if present
    const jsonBlock = extractJsonBlock(auditReport);
    if (jsonBlock) {
      yield {
        type: 'artifact',
        name: 'audit-report.json',
        content: jsonBlock,
        mimeType: 'application/json',
      };
    }

    yield {
      type: 'result',
      data: auditReport,
      message: `Security audit completed for ${languageLabel} contract`,
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error';
    console.error('[audit-contract] Audit failed:', errorMessage);
    yield {
      type: 'error',
      message: `Failed to perform security audit: ${errorMessage}`,
    };
  }
}
