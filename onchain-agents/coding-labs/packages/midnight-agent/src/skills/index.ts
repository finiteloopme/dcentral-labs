/**
 * Midnight Agent Skills Registry
 *
 * Defines skill types, handlers, and detection logic.
 */

import type { Message } from '@a2a-js/sdk';
import { generateCompact } from './compact-gen.js';
import { compileCompact } from './compile.js';
import { queryState } from './query-state.js';
import { deployContractSkill } from './deploy.js';
import { callCircuitSkill } from './call.js';
import { managePrivateState } from './private-state.js';

/**
 * Artifact structure for passing compiled contract files.
 */
export interface Artifact {
  filename: string;
  content: string;
  mimeType?: string;
}

/**
 * Session context passed between skill invocations.
 * Tracks state from previous operations (e.g., artifacts from compile step).
 */
export interface SessionContext {
  /** Compiled contract artifacts (from compile skill via MCP) */
  artifacts?: Artifact[];
  /** Name of the contract (extracted from source or user input) */
  contractName?: string;
  /** Address of a deployed contract (from deploy skill) */
  contractAddress?: string;
  /** Target network (preview, preprod, local) */
  network?: string;
}

/**
 * Events emitted by skill handlers during execution
 */
export type SkillEvent =
  | { type: 'status'; message: string }
  | { type: 'artifact'; name: string; content: string; mimeType?: string }
  | { type: 'result'; data: unknown; message?: string }
  | { type: 'error'; message: string }
  | { type: 'session-update'; context: Partial<SessionContext> };

/**
 * Skill handler function signature
 */
export type SkillHandler = (
  message: Message,
  session?: SessionContext
) => AsyncGenerator<SkillEvent, void, unknown>;

/**
 * Map of skill IDs to their handler functions
 */
export const skillHandlers: Record<string, SkillHandler> = {
  'compact-gen': generateCompact,
  compile: compileCompact,
  'query-state': queryState,
  deploy: deployContractSkill,
  call: callCircuitSkill,
  'private-state': managePrivateState,
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
 * Continuation phrases that indicate user wants to proceed with workflow.
 */
const CONTINUATION_PHRASES = [
  'yes',
  'ok',
  'okay',
  'sure',
  'proceed',
  'continue',
  'next',
  'do it',
  'go ahead',
  'go on',
  'yep',
  'yeah',
  'y',
];

/**
 * Check if the message is a continuation/confirmation phrase.
 */
function isContinuation(text: string): boolean {
  const trimmed = text.trim().toLowerCase();
  // Check exact match or phrase at start/end
  return CONTINUATION_PHRASES.some(
    (phrase) =>
      trimmed === phrase ||
      trimmed.startsWith(phrase + ' ') ||
      trimmed.startsWith(phrase + ',') ||
      trimmed.startsWith(phrase + '!')
  );
}

/**
 * Determine the next logical skill based on session state.
 * Used when user confirms/continues without explicit instruction.
 */
function getNextWorkflowStep(session: SessionContext): string | null {
  // If deployed, suggest calling circuits
  if (session.contractAddress) {
    return 'call';
  }
  // If compiled but not deployed, proceed to deploy
  if (session.artifacts && session.artifacts.length > 0) {
    return 'deploy';
  }
  // If we have contract name but no artifacts, compile
  if (session.contractName) {
    return 'compile';
  }
  // No state - can't determine next step
  return null;
}

/**
 * Detect which skill should handle a message based on content analysis.
 *
 * Priority order:
 *   0. Continuation phrases (yes, ok, continue) → check session for next step
 *   1. Code generation (most common, shares vocabulary with other skills)
 *   2. Compile (explicit "compile" or code block provided)
 *   3. Deploy
 *   4. Call circuit
 *   5. Query state (tightened patterns to avoid false positives)
 *   6. Private state
 *   7. Session-aware default (avoid regenerating code if artifacts exist)
 *   8. Default → code generation
 */
export function detectSkill(
  userText: string,
  session?: SessionContext
): string {
  const text = userText.toLowerCase();

  // 0. Check for continuation phrases first
  if (isContinuation(text) && session) {
    const nextStep = getNextWorkflowStep(session);
    if (nextStep) {
      console.log(
        `[detectSkill] Continuation detected, next workflow step: ${nextStep}`
      );
      return nextStep;
    }
  }

  // 1. Code generation - check FIRST since generation requests naturally
  //    contain words like "ledger", "state", "circuit" that overlap other skills
  if (
    text.includes('generate') ||
    text.includes('create') ||
    text.includes('write') ||
    text.includes('build me') ||
    text.includes('make a') ||
    text.includes('make me') ||
    text.includes('implement') ||
    text.includes('code for') ||
    text.includes('contract for') ||
    text.includes('contract that') ||
    text.includes('contract with') ||
    text.includes('smart contract') ||
    text.includes('write a') ||
    text.includes('design a')
  ) {
    return 'compact-gen';
  }

  // 2. Compile - only when user explicitly asks to compile existing code
  if (
    text.includes('compile') ||
    text.includes('.compact file') ||
    text.includes('```compact')
  ) {
    return 'compile';
  }

  // 3. Deploy
  if (text.includes('deploy') || text.includes('publish contract')) {
    return 'deploy';
  }

  // 4. Call circuit
  if (
    text.includes('call circuit') ||
    text.includes('execute circuit') ||
    text.includes('run circuit') ||
    text.includes('invoke circuit')
  ) {
    return 'call';
  }

  // 5. Query state - specific patterns only, avoid generic words
  //    that appear in code generation requests
  if (
    text.includes('query state') ||
    text.includes('query contract') ||
    text.includes('query ledger') ||
    text.includes('get state of') ||
    text.includes('read state of') ||
    text.includes('read ledger of') ||
    text.includes('check state') ||
    text.includes('what is the state') ||
    (text.includes('query') && /0x[a-fA-F0-9]{40,}/.test(text))
  ) {
    return 'query-state';
  }

  // 6. Private state
  if (
    text.includes('private state') ||
    text.includes('manage private') ||
    text.includes('local state')
  ) {
    return 'private-state';
  }

  // 7. Session-aware default: if contract is deployed,
  //    ambiguous messages about executing/calling should go to call skill
  if (session?.contractAddress) {
    // Check for call-like intent without requiring exact patterns
    if (
      text.includes('increment') ||
      text.includes('decrement') ||
      text.includes('execute') ||
      text.includes('invoke') ||
      text.includes('run') ||
      text.includes('call')
    ) {
      console.log(
        '[detectSkill] Contract deployed, routing to call skill for circuit execution'
      );
      return 'call';
    }
  }

  // 8. Session-aware default: if artifacts exist but not deployed,
  //    ambiguous messages should NOT regenerate code
  if (
    session?.artifacts &&
    session.artifacts.length > 0 &&
    !session.contractAddress
  ) {
    console.log(
      '[detectSkill] Artifacts exist but not deployed, suggesting deploy instead of code gen'
    );
    return 'deploy';
  }

  // 9. Default to code generation
  return 'compact-gen';
}
