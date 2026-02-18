/**
 * Session management for EVM MCP server.
 *
 * Key constraints:
 * - Only ONE EVM agent can use evm-mcp per session
 * - Once a chain is selected, cannot switch mid-session
 * - Session includes an Anvil fork process (lazy started)
 */

import type { ChildProcess } from 'child_process';
import type { ChainConfig } from './config.js';

// -----------------------------------------------------------------------------
// Session State
// -----------------------------------------------------------------------------

export interface SessionState {
  /** Unique session identifier */
  sessionId: string;
  /** Agent that owns this session (e.g., 'sonic-agent', 'somnia-agent') */
  agentId: string;
  /** Chain configuration for this session */
  chainConfig: ChainConfig;
  /** Anvil child process (null if not started) */
  anvilProcess: ChildProcess | null;
  /** Local Anvil RPC URL */
  anvilRpcUrl: string;
  /** When session was locked */
  lockedAt: Date;
}

// Only one session at a time (single Anvil instance)
let currentSession: SessionState | null = null;

// -----------------------------------------------------------------------------
// Session Management
// -----------------------------------------------------------------------------

/**
 * Acquire a session for an agent.
 *
 * @throws Error if session is already locked by another agent/session
 * @throws Error if trying to switch chains mid-session
 */
export function acquireSession(
  sessionId: string,
  agentId: string,
  chainConfig: ChainConfig,
  anvilPort: number
): SessionState {
  // Check if another session is active
  if (currentSession && currentSession.sessionId !== sessionId) {
    throw new Error(
      `EVM MCP is currently locked by ${currentSession.agentId} (session: ${currentSession.sessionId}). ` +
        `Only one EVM agent can use evm-mcp per session. ` +
        `Wait for current session to end, or start a new session.`
    );
  }

  // Check if trying to switch chains mid-session
  if (
    currentSession &&
    currentSession.sessionId === sessionId &&
    currentSession.chainConfig.chainId !== chainConfig.chainId
  ) {
    throw new Error(
      `Cannot switch chains mid-session. ` +
        `Current: ${currentSession.chainConfig.name} (${currentSession.chainConfig.chainId}), ` +
        `Requested: ${chainConfig.name} (${chainConfig.chainId}). ` +
        `Start a new session to use a different chain.`
    );
  }

  // Create new session if none exists
  if (!currentSession) {
    currentSession = {
      sessionId,
      agentId,
      chainConfig,
      anvilProcess: null,
      anvilRpcUrl: `http://localhost:${anvilPort}`,
      lockedAt: new Date(),
    };
    console.log(
      `[evm-mcp] Session acquired by ${agentId} for ${chainConfig.name} (chainId: ${chainConfig.chainId})`
    );
  }

  return currentSession;
}

/**
 * Get the current session state.
 */
export function getSession(): SessionState | null {
  return currentSession;
}

/**
 * Check if a session is active.
 */
export function hasActiveSession(): boolean {
  return currentSession !== null;
}

/**
 * Update the Anvil process for the current session.
 */
export function setAnvilProcess(process: ChildProcess): void {
  if (currentSession) {
    currentSession.anvilProcess = process;
  }
}

/**
 * Release the current session.
 * Kills Anvil process if running.
 */
export function releaseSession(sessionId?: string): void {
  if (!currentSession) {
    return;
  }

  // If sessionId provided, only release if it matches
  if (sessionId && currentSession.sessionId !== sessionId) {
    return;
  }

  // Kill Anvil process if running
  if (currentSession.anvilProcess) {
    console.log(
      `[evm-mcp] Stopping Anvil process for session ${currentSession.sessionId}`
    );
    currentSession.anvilProcess.kill('SIGTERM');
  }

  console.log(
    `[evm-mcp] Session released: ${currentSession.sessionId} (was locked by ${currentSession.agentId})`
  );
  currentSession = null;
}

/**
 * Get session info for health/status endpoints.
 */
export function getSessionInfo(): {
  hasActiveSession: boolean;
  sessionId?: string;
  agentId?: string;
  chainId?: number;
  chainName?: string;
  anvilRunning?: boolean;
  lockedAt?: string;
} {
  if (!currentSession) {
    return { hasActiveSession: false };
  }

  return {
    hasActiveSession: true,
    sessionId: currentSession.sessionId,
    agentId: currentSession.agentId,
    chainId: currentSession.chainConfig.chainId,
    chainName: currentSession.chainConfig.name,
    anvilRunning: currentSession.anvilProcess !== null,
    lockedAt: currentSession.lockedAt.toISOString(),
  };
}
