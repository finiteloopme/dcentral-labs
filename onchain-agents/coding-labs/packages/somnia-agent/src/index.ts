import express from 'express';
import type { TaskStore } from '@a2a-js/sdk/server';
import {
  InMemoryTaskStore,
  DefaultRequestHandler,
} from '@a2a-js/sdk/server';
import { A2AExpressApp } from '@a2a-js/sdk/server/express';
import { somniaAgentCard } from './agent-card.js';
import { SomniaAgentExecutor } from './executor.js';

// Support both PORT (Cloud Run) and SOMNIA_AGENT_PORT (local dev)
const PORT = parseInt(process.env.PORT || process.env.SOMNIA_AGENT_PORT || '4001', 10);

async function main() {
  console.log('[SomniaAgent] Starting Somnia Agent...');

  // 1. Create TaskStore
  const taskStore: TaskStore = new InMemoryTaskStore();

  // 2. Create AgentExecutor
  const agentExecutor = new SomniaAgentExecutor();

  // 3. Create DefaultRequestHandler
  const requestHandler = new DefaultRequestHandler(
    somniaAgentCard,
    taskStore,
    agentExecutor
  );

  // 4. Create and setup A2AExpressApp
  const appBuilder = new A2AExpressApp(requestHandler);
  const expressApp = appBuilder.setupRoutes(express(), '');

  // 5. Add health check endpoint
  expressApp.get('/health', (_req, res) => {
    res.json({ status: 'healthy', agent: 'somnia-agent', version: '0.1.0' });
  });

  // 6. Add A2A spec-compliant agent.json route (alias for agent-card.json)
  expressApp.get('/.well-known/agent.json', (_req, res) => {
    res.json(somniaAgentCard);
  });

  // 7. Start the server
  expressApp.listen(PORT, () => {
    console.log(`[SomniaAgent] Server started on http://localhost:${PORT}`);
    console.log(
      `[SomniaAgent] Agent Card: http://localhost:${PORT}/.well-known/agent.json`
    );
    console.log(`[SomniaAgent] Health: http://localhost:${PORT}/health`);
    console.log('[SomniaAgent] Press Ctrl+C to stop the server');
    console.log('');
    console.log('[SomniaAgent] Available skills:');
    somniaAgentCard.skills?.forEach((skill) => {
      console.log(`  - ${skill.id}: ${skill.name}`);
    });
  });
}

main().catch((error) => {
  console.error('[SomniaAgent] Failed to start:', error);
  process.exit(1);
});
