/**
 * Security Agent - A2A Server Entry Point
 *
 * Provides AI-powered security auditing, vulnerability scanning,
 * and protocol risk assessment for smart contracts and blockchain ecosystems.
 */

import express from 'express';
import cors from 'cors';
import type { TaskStore } from '@a2a-js/sdk/server';
import { InMemoryTaskStore, DefaultRequestHandler } from '@a2a-js/sdk/server';
import { A2AExpressApp } from '@a2a-js/sdk/server/express';
import { securityAgentCard } from './agent-card.js';
import { SecurityAgentExecutor } from './executor.js';

// Import config loader for fallback values
let configPort = 4006;
let configHost = 'localhost';
try {
  // Dynamic import to handle cases where config.toml doesn't exist
  const { loadConfigFile, getServiceConfig, findConfigPath } =
    await import('@coding-labs/shared/config');
  const configPath = findConfigPath();
  if (configPath) {
    const config = loadConfigFile(configPath);
    const serviceConfig = getServiceConfig(config, 'security-agent');
    configPort = serviceConfig.port;
    configHost = serviceConfig.host;
    console.log(`[SecurityAgent] Loaded config from ${configPath}`);
  }
} catch {
  // Config not available, use defaults
  console.log('[SecurityAgent] No config.toml found, using defaults');
}

// Resolution order: ENV vars > config.toml > hardcoded defaults
const PORT = parseInt(
  process.env.PORT || process.env.SECURITY_AGENT_PORT || String(configPort),
  10
);
const HOST = process.env.HOST || process.env.SECURITY_AGENT_HOST || configHost;

async function main() {
  console.log('[SecurityAgent] Starting Security Agent...');

  // 1. Create TaskStore
  const taskStore: TaskStore = new InMemoryTaskStore();

  // 2. Create AgentExecutor
  const agentExecutor = new SecurityAgentExecutor();

  // 3. Create DefaultRequestHandler
  const requestHandler = new DefaultRequestHandler(
    securityAgentCard,
    taskStore,
    agentExecutor
  );

  // 4. Create and setup A2AExpressApp
  const appBuilder = new A2AExpressApp(requestHandler);
  const app = express();
  app.use(cors());
  const expressApp = appBuilder.setupRoutes(app, '');

  // 5. Add health check endpoint
  expressApp.get('/health', (_req, res) => {
    res.json({ status: 'healthy', agent: 'security-agent', version: '0.1.0' });
  });

  // 6. Add A2A spec-compliant agent.json route (alias for agent-card.json)
  expressApp.get('/.well-known/agent.json', (_req, res) => {
    res.json(securityAgentCard);
  });

  // 7. Start the server
  expressApp.listen(PORT, HOST, () => {
    console.log(`[SecurityAgent] Server started on http://${HOST}:${PORT}`);
    console.log(
      `[SecurityAgent] Agent Card: http://localhost:${PORT}/.well-known/agent.json`
    );
    console.log(`[SecurityAgent] Health: http://localhost:${PORT}/health`);
    console.log('[SecurityAgent] Press Ctrl+C to stop the server');
    console.log('');
    console.log('[SecurityAgent] Available skills:');
    securityAgentCard.skills?.forEach((skill) => {
      console.log(`  - ${skill.id}: ${skill.name}`);
    });
  });
}

main().catch((error) => {
  console.error('[SecurityAgent] Failed to start:', error);
  process.exit(1);
});
