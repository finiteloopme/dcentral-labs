import express from 'express';
import type { TaskStore } from '@a2a-js/sdk/server';
import { InMemoryTaskStore, DefaultRequestHandler } from '@a2a-js/sdk/server';
import { A2AExpressApp } from '@a2a-js/sdk/server/express';
import { somniaAgentCard } from './agent-card.js';
import { SomniaAgentExecutor } from './executor.js';

// Import config loader for fallback values
let configPort = 4001;
let configHost = 'localhost';
try {
  // Dynamic import to handle cases where config.toml doesn't exist
  const { loadConfigFile, getServiceConfig, findConfigPath } =
    await import('@coding-labs/shared/config');
  const configPath = findConfigPath();
  if (configPath) {
    const config = loadConfigFile(configPath);
    const serviceConfig = getServiceConfig(config, 'somnia-agent');
    configPort = serviceConfig.port;
    configHost = serviceConfig.host;
    console.log(`[SomniaAgent] Loaded config from ${configPath}`);
  }
} catch {
  // Config not available, use defaults
  console.log('[SomniaAgent] No config.toml found, using defaults');
}

// Resolution order: ENV vars > config.toml > hardcoded defaults
const PORT = parseInt(
  process.env.PORT || process.env.SOMNIA_AGENT_PORT || String(configPort),
  10
);
const HOST = process.env.HOST || process.env.SOMNIA_AGENT_HOST || configHost;

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
  expressApp.listen(PORT, HOST, () => {
    console.log(`[SomniaAgent] Server started on http://${HOST}:${PORT}`);
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
