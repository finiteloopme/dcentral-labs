/**
 * Agent Playground - Root ADK Agent
 *
 * Orchestrates blockchain agents (Somnia, Sonic, Midnight, Store, Payment, Security)
 * via the A2A protocol using Google ADK's RemoteA2AAgent.
 *
 * The root agent receives user messages and routes them to the appropriate
 * blockchain agent based on the user's intent.
 */

import { LlmAgent, RemoteA2AAgent } from '@google/adk';
import {
  loadConfigFile,
  getEnabledAgents,
  getServiceConfig,
  getServiceUrl,
} from '@coding-labs/shared/config';

/**
 * Build the base URL for a blockchain agent from config.
 * RemoteA2AAgent expects the base URL (not the agent card URL).
 * It will automatically fetch /.well-known/agent-card.json from there.
 */
function getAgentBaseUrl(agentUrl: string): string {
  // Ensure no trailing slash
  return agentUrl.replace(/\/$/, '');
}

/**
 * Create RemoteA2AAgent instances for all enabled blockchain agents.
 */
function createRemoteAgents(): RemoteA2AAgent[] {
  const config = loadConfigFile();
  const env = process.env.NODE_ENV || 'development';
  const enabledAgents = getEnabledAgents(config, env);

  const remoteAgents: RemoteA2AAgent[] = [];

  for (const agent of enabledAgents) {
    const baseUrl = getAgentBaseUrl(agent.url);
    console.log(`[adk-backend] Registering remote agent: ${agent.name} → ${baseUrl}`);

    const remoteAgent = new RemoteA2AAgent({
      name: agent.id.replace(/-/g, '_'), // ADK requires alphanumeric + underscore
      description: agent.description,
      agentCard: baseUrl,
    });

    remoteAgents.push(remoteAgent);
  }

  return remoteAgents;
}

// Create sub-agents from config
const subAgents = createRemoteAgents();

/**
 * Root agent - "Agent Playground"
 *
 * This is the main orchestrator that routes user requests to the appropriate
 * blockchain agent. It uses Gemini as the LLM for intent classification
 * and response synthesis.
 */
export const rootAgent = new LlmAgent({
  name: 'agent_playground',
  model: 'gemini-2.0-flash',
  description:
    'Agent Playground - Multi-chain blockchain development assistant. ' +
    'Routes requests to specialized blockchain agents for Somnia, Sonic, ' +
    'Midnight, Store, Payment, and Security operations.',
  instruction: `You are the Agent Playground, a multi-chain blockchain development assistant.

You have access to specialized blockchain agents as sub-agents:

${subAgents.map((a) => `- **${a.name}**: ${a.description || 'Blockchain agent'}`).join('\n')}

When a user asks about a specific blockchain or operation:
1. Identify which agent(s) can handle the request based on the description
2. Route the request to the appropriate agent
3. If the request spans multiple chains, coordinate between agents
4. If unsure which agent to use, ask the user for clarification

For general blockchain questions not specific to any chain, provide helpful guidance
and suggest which agent might be most appropriate.

Always be helpful, concise, and accurate. When routing to a sub-agent, pass the
user's full context so the agent can provide the best response.`,
  subAgents,
});
