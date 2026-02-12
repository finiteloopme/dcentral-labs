/**
 * Midnight Agent - A2A Server Entry Point
 *
 * Provides AI-powered assistance for Midnight Network development,
 * including Compact smart contract generation.
 */

import express from 'express';
import type { TaskStore } from '@a2a-js/sdk/server';
import { InMemoryTaskStore, DefaultRequestHandler } from '@a2a-js/sdk/server';
import { A2AExpressApp } from '@a2a-js/sdk/server/express';
import { midnightAgentCard } from './agent-card.js';
import { MidnightAgentExecutor } from './executor.js';

// Import config loader for fallback values
let configPort = 4003;
let configHost = 'localhost';
try {
  // Dynamic import to handle cases where config.toml doesn't exist
  const { loadConfigFile, getServiceConfig, findConfigPath } =
    await import('@coding-labs/shared/config');
  const configPath = findConfigPath();
  if (configPath) {
    const config = loadConfigFile(configPath);
    const serviceConfig = getServiceConfig(config, 'midnight-agent');
    configPort = serviceConfig.port;
    configHost = serviceConfig.host;
    console.log(`[MidnightAgent] Loaded config from ${configPath}`);
  }
} catch {
  // Config not available, use defaults
  console.log('[MidnightAgent] No config.toml found, using defaults');
}

// Resolution order: ENV vars > config.toml > hardcoded defaults
const PORT = parseInt(
  process.env.PORT || process.env.MIDNIGHT_AGENT_PORT || String(configPort),
  10
);
const HOST = process.env.HOST || process.env.MIDNIGHT_AGENT_HOST || configHost;

async function main() {
  console.log('[MidnightAgent] Starting Midnight Agent...');

  // 1. Create TaskStore
  const taskStore: TaskStore = new InMemoryTaskStore();

  // 2. Create AgentExecutor
  const agentExecutor = new MidnightAgentExecutor();

  // 3. Create DefaultRequestHandler
  const requestHandler = new DefaultRequestHandler(
    midnightAgentCard,
    taskStore,
    agentExecutor
  );

  // 4. Create and setup A2AExpressApp
  const appBuilder = new A2AExpressApp(requestHandler);
  const expressApp = appBuilder.setupRoutes(express(), '');

  // 5. Add health check endpoint
  expressApp.get('/health', (_req, res) => {
    res.json({ status: 'healthy', agent: 'midnight-agent', version: '0.1.0' });
  });

  // 6. Add A2A spec-compliant agent.json route (alias for agent-card.json)
  expressApp.get('/.well-known/agent.json', (_req, res) => {
    res.json(midnightAgentCard);
  });

  // 7. Start the server
  expressApp.listen(PORT, HOST, () => {
    console.log(`[MidnightAgent] Server started on http://${HOST}:${PORT}`);
    console.log(
      `[MidnightAgent] Agent Card: http://localhost:${PORT}/.well-known/agent.json`
    );
    console.log(`[MidnightAgent] Health: http://localhost:${PORT}/health`);
    console.log('[MidnightAgent] Press Ctrl+C to stop the server');
    console.log('');
    console.log('[MidnightAgent] Available skills:');
    midnightAgentCard.skills?.forEach((skill) => {
      console.log(`  - ${skill.id}: ${skill.name}`);
    });
  });
}

main().catch((error) => {
  console.error('[MidnightAgent] Failed to start:', error);
  process.exit(1);
});
