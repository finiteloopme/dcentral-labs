/**
 * Security Agent Skills Registry
 *
 * Defines skill types, handlers, and detection logic.
 */

import type { Message } from '@a2a-js/sdk';
import { auditContract } from './audit-contract.js';
import { scanVulnerabilities } from './scan-vulnerabilities.js';
import { assessRisk } from './assess-risk.js';
import { explainFinding } from './explain-finding.js';
import { compareProtocols } from './compare-protocols.js';

/**
 * Events emitted by skill handlers during execution
 */
export type SkillEvent =
  | { type: 'status'; message: string }
  | { type: 'artifact'; name: string; content: string; mimeType?: string }
  | { type: 'result'; data: unknown; message?: string }
  | { type: 'error'; message: string };

/**
 * Skill handler function signature
 */
export type SkillHandler = (
  message: Message
) => AsyncGenerator<SkillEvent, void, unknown>;

/**
 * Map of skill IDs to their handler functions
 */
export const skillHandlers: Record<string, SkillHandler> = {
  'audit-contract': auditContract,
  'scan-vulnerabilities': scanVulnerabilities,
  'assess-risk': assessRisk,
  'explain-finding': explainFinding,
  'compare-protocols': compareProtocols,
};

/**
 * Extract text content from a message
 * Handles both A2A SDK format (kind: 'text') and raw JSON format (type: 'text')
 */
export function extractTextFromMessage(message: Message): string {
  return message.parts
    .filter((p) => {
      const part = p as { kind?: string; type?: string };
      return part.kind === 'text' || part.type === 'text';
    })
    .map((p) => {
      const part = p as { text?: string };
      return part.text ?? '';
    })
    .join('\n');
}

/**
 * Detect which skill should handle a message based on content analysis.
 *
 * Priority order:
 *   1. compare-protocols (explicit comparison intent)
 *   2. explain-finding (educational deep-dive on a vulnerability)
 *   3. assess-risk (protocol/ecosystem risk assessment)
 *   4. scan-vulnerabilities (quick targeted scan)
 *   5. audit-contract (comprehensive audit — default)
 */
export function detectSkill(userText: string): string {
  const text = userText.toLowerCase();

  // 1. Compare protocols
  if (
    text.includes('compare') ||
    text.includes(' vs ') ||
    text.includes('versus') ||
    text.includes('difference between') ||
    text.includes('differences between')
  ) {
    return 'compare-protocols';
  }

  // 2. Explain finding (educational deep-dive)
  const vulnerabilityTerms = [
    'reentrancy',
    'overflow',
    'underflow',
    'front-running',
    'frontrunning',
    'flash loan',
    'oracle manipulation',
    'delegatecall',
    'selfdestruct',
    'self-destruct',
    'replay attack',
    'sandwich attack',
    'rug pull',
    'access control',
    'integer overflow',
    'storage collision',
    'signature replay',
    'witness validation',
    'disclosure leak',
    'gas griefing',
    'denial of service',
    'dos',
    'mev',
  ];

  const hasVulnerabilityTerm = vulnerabilityTerms.some((term) =>
    text.includes(term)
  );

  if (
    (text.includes('explain') ||
      text.includes('what is') ||
      text.includes('tell me about') ||
      text.includes('deep dive') ||
      text.includes('how does') ||
      text.includes('how do')) &&
    hasVulnerabilityTerm
  ) {
    return 'explain-finding';
  }

  // 3. Assess risk (protocol/ecosystem level)
  if (
    text.includes('risk') ||
    text.includes('assess') ||
    text.includes('protocol risk') ||
    text.includes('ecosystem') ||
    text.includes('how safe') ||
    text.includes('due diligence') ||
    text.includes('risk profile')
  ) {
    return 'assess-risk';
  }

  // 4. Scan vulnerabilities (quick targeted scan)
  if (
    text.includes('scan') ||
    text.includes('vulnerability') ||
    text.includes('vulnerabilities') ||
    text.includes('find bugs') ||
    text.includes('quick check') ||
    text.includes('pattern check')
  ) {
    return 'scan-vulnerabilities';
  }

  // 5. Audit contract (comprehensive — also the default)
  if (
    text.includes('audit') ||
    text.includes('review') ||
    text.includes('check security') ||
    text.includes('security review')
  ) {
    return 'audit-contract';
  }

  // Default to audit-contract
  return 'audit-contract';
}
