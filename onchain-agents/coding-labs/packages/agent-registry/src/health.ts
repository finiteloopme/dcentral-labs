/**
 * Agent Health Check Utility
 *
 * Provides functions to check the health status of registered agents.
 * Used by the /agents/health endpoint for lazy health checking.
 */

import type { AgentInfo } from '@coding-labs/shared/config';

/**
 * Health status for a single agent
 */
export interface AgentHealthStatus {
  id: string;
  name: string;
  url: string;
  healthy: boolean;
  latencyMs: number | null;
  error?: string;
}

/**
 * Health check response for all agents
 */
export interface AgentHealthResponse {
  agents: AgentHealthStatus[];
  checkedAt: string;
}

/**
 * Default timeout for health checks (5 seconds)
 */
const HEALTH_CHECK_TIMEOUT_MS = 5000;

/**
 * Check the health of a single agent by calling its /health endpoint.
 *
 * @param agent - Agent info from the registry
 * @param timeoutMs - Timeout for the health check request
 * @returns Health status for the agent
 */
export async function checkAgentHealth(
  agent: AgentInfo,
  timeoutMs: number = HEALTH_CHECK_TIMEOUT_MS
): Promise<AgentHealthStatus> {
  const startTime = Date.now();

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

    const healthUrl = `${agent.url}/health`;
    const response = await fetch(healthUrl, {
      method: 'GET',
      signal: controller.signal,
      headers: {
        Accept: 'application/json',
      },
    });

    clearTimeout(timeoutId);
    const latencyMs = Date.now() - startTime;

    if (response.ok) {
      return {
        id: agent.id,
        name: agent.name,
        url: agent.url,
        healthy: true,
        latencyMs,
      };
    } else {
      return {
        id: agent.id,
        name: agent.name,
        url: agent.url,
        healthy: false,
        latencyMs,
        error: `HTTP ${response.status}: ${response.statusText}`,
      };
    }
  } catch (error) {
    const latencyMs = Date.now() - startTime;
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error';

    // Check if it was a timeout
    const isTimeout = error instanceof Error && error.name === 'AbortError';

    return {
      id: agent.id,
      name: agent.name,
      url: agent.url,
      healthy: false,
      latencyMs: isTimeout ? null : latencyMs,
      error: isTimeout ? `Timeout after ${timeoutMs}ms` : errorMessage,
    };
  }
}

/**
 * Check the health of multiple agents in parallel.
 *
 * @param agents - List of agents to check
 * @param timeoutMs - Timeout for each health check request
 * @returns Health response with status for all agents
 */
export async function checkAllAgentsHealth(
  agents: AgentInfo[],
  timeoutMs: number = HEALTH_CHECK_TIMEOUT_MS
): Promise<AgentHealthResponse> {
  const healthChecks = agents.map((agent) =>
    checkAgentHealth(agent, timeoutMs)
  );

  const results = await Promise.all(healthChecks);

  return {
    agents: results,
    checkedAt: new Date().toISOString(),
  };
}
