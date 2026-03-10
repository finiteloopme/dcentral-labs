import express from 'express';
import type { TaskStore } from '@a2a-js/sdk/server';
import { InMemoryTaskStore, DefaultRequestHandler } from '@a2a-js/sdk/server';
import { A2AExpressApp } from '@a2a-js/sdk/server/express';
import { storeAgentCard } from './agent-card.js';
import { StoreAgentExecutor } from './executor.js';

let configPort = 4004;
let configHost = 'localhost';
try {
  const { loadConfigFile, getServiceConfig, findConfigPath } =
    await import('@coding-labs/shared/config');
  const configPath = findConfigPath();
  if (configPath) {
    const config = loadConfigFile(configPath);
    const serviceConfig = getServiceConfig(config, 'store-agent');
    configPort = serviceConfig.port;
    configHost = serviceConfig.host;
    console.log(`[StoreAgent] Loaded config from ${configPath}`);
  }
} catch {
  console.log('[StoreAgent] No config.toml found, using defaults');
}

const PORT = parseInt(
  process.env.PORT || process.env.STORE_AGENT_PORT || String(configPort),
  10
);
const HOST = process.env.HOST || process.env.STORE_AGENT_HOST || configHost;

async function main() {
  console.log('[StoreAgent] Starting Store Agent...');

  const taskStore: TaskStore = new InMemoryTaskStore();
  const agentExecutor = new StoreAgentExecutor();
  const requestHandler = new DefaultRequestHandler(
    storeAgentCard,
    taskStore,
    agentExecutor
  );

  const appBuilder = new A2AExpressApp(requestHandler);
  const expressApp = appBuilder.setupRoutes(express(), '');

  expressApp.get('/health', (_req, res) => {
    res.json({ status: 'healthy', agent: 'store-agent', version: '0.1.0' });
  });

  expressApp.get('/.well-known/agent.json', (_req, res) => {
    res.json(storeAgentCard);
  });

  expressApp.listen(PORT, HOST, () => {
    console.log(`[StoreAgent] Server started on http://${HOST}:${PORT}`);
    console.log(`[StoreAgent] Agent Card: http://localhost:${PORT}/.well-known/agent.json`);
    console.log(`[StoreAgent] Health: http://localhost:${PORT}/health`);
    console.log('[StoreAgent] Press Ctrl+C to stop the server');
    console.log('');
    console.log('[StoreAgent] Available skills:');
    storeAgentCard.skills?.forEach((skill) => {
      console.log(`  - ${skill.id}: ${skill.name}`);
    });
  });
}

main().catch((error) => {
  console.error('[StoreAgent] Failed to start:', error);
  process.exit(1);
});
