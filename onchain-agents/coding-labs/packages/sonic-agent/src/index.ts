import express from 'express';
import cors from 'cors';
import type { TaskStore } from '@a2a-js/sdk/server';
import { InMemoryTaskStore, DefaultRequestHandler } from '@a2a-js/sdk/server';
import { A2AExpressApp } from '@a2a-js/sdk/server/express';
import { sonicAgentCard } from './agent-card.js';
import { SonicAgentExecutor } from './executor.js';

// Import config loader for fallback values
let configPort = 4002;
let configHost = 'localhost';
try {
  // Dynamic import to handle cases where config.toml doesn't exist
  const { loadConfigFile, getServiceConfig, findConfigPath } =
    await import('@coding-labs/shared/config');
  const configPath = findConfigPath();
  if (configPath) {
    const config = loadConfigFile(configPath);
    const serviceConfig = getServiceConfig(config, 'sonic-agent');
    configPort = serviceConfig.port;
    configHost = serviceConfig.host;
    console.log(`[SonicAgent] Loaded config from ${configPath}`);
  }
} catch {
  // Config not available, use defaults
  console.log('[SonicAgent] No config.toml found, using defaults');
}

// Resolution order: ENV vars > config.toml > hardcoded defaults
const PORT = parseInt(
  process.env.PORT || process.env.SONIC_AGENT_PORT || String(configPort),
  10
);
const HOST = process.env.HOST || process.env.SONIC_AGENT_HOST || configHost;

async function main() {
  console.log('[SonicAgent] Starting Sonic Agent...');

  // 1. Create TaskStore
  const taskStore: TaskStore = new InMemoryTaskStore();

  // 2. Create AgentExecutor
  const agentExecutor = new SonicAgentExecutor();

  // 3. Create DefaultRequestHandler
  const requestHandler = new DefaultRequestHandler(
    sonicAgentCard,
    taskStore,
    agentExecutor
  );

  // 4. Create and setup A2AExpressApp with CORS middleware
  const appBuilder = new A2AExpressApp(requestHandler);
  const app = express();
  app.use(cors());
  const expressApp = appBuilder.setupRoutes(app, '');

  // 5. Add health check endpoint
  expressApp.get('/health', (_req, res) => {
    res.json({ status: 'healthy', agent: 'sonic-agent', version: '0.1.0' });
  });

  // 6. Add A2A spec-compliant agent.json route (alias for agent-card.json)
  expressApp.get('/.well-known/agent.json', (_req, res) => {
    res.json(sonicAgentCard);
  });

  // 7. Start the server
  expressApp.listen(PORT, HOST, () => {
    console.log(`[SonicAgent] Server started on http://${HOST}:${PORT}`);
    console.log(
      `[SonicAgent] Agent Card: http://localhost:${PORT}/.well-known/agent.json`
    );
    console.log(`[SonicAgent] Health: http://localhost:${PORT}/health`);
    console.log('[SonicAgent] Press Ctrl+C to stop the server');
    console.log('');
    console.log('[SonicAgent] Available skills:');
    sonicAgentCard.skills?.forEach((skill) => {
      console.log(`  - ${skill.id}: ${skill.name}`);
    });
  });
}

main().catch((error) => {
  console.error('[SonicAgent] Failed to start:', error);
  process.exit(1);
});
