import express from 'express';
import type { TaskStore } from '@a2a-js/sdk/server';
import { InMemoryTaskStore, DefaultRequestHandler } from '@a2a-js/sdk/server';
import { A2AExpressApp } from '@a2a-js/sdk/server/express';
import { paymentAgentCard } from './agent-card.js';
import { PaymentAgentExecutor } from './executor.js';
import { createFacilitatorRouter } from './facilitator.js';

let configPort = 4005;
let configHost = 'localhost';
try {
  const { loadConfigFile, getServiceConfig, findConfigPath } =
    await import('@coding-labs/shared/config');
  const configPath = findConfigPath();
  if (configPath) {
    const config = loadConfigFile(configPath);
    const serviceConfig = getServiceConfig(config, 'payment-agent');
    configPort = serviceConfig.port;
    configHost = serviceConfig.host;
    console.log(`[PaymentAgent] Loaded config from ${configPath}`);
  }
} catch {
  console.log('[PaymentAgent] No config.toml found, using defaults');
}

const PORT = parseInt(
  process.env.PORT || process.env.PAYMENT_AGENT_PORT || String(configPort),
  10
);
const HOST = process.env.HOST || process.env.PAYMENT_AGENT_HOST || configHost;

async function main() {
  console.log('[PaymentAgent] Starting Payment Agent...');

  const taskStore: TaskStore = new InMemoryTaskStore();
  const agentExecutor = new PaymentAgentExecutor();
  const requestHandler = new DefaultRequestHandler(
    paymentAgentCard,
    taskStore,
    agentExecutor
  );

  const appBuilder = new A2AExpressApp(requestHandler);
  const expressApp = appBuilder.setupRoutes(express(), '');

  // Mount x402 facilitator endpoints
  expressApp.use(createFacilitatorRouter());
  console.log('[PaymentAgent] x402 facilitator endpoints mounted at /x402/*');

  expressApp.get('/health', (_req, res) => {
    res.json({ status: 'healthy', agent: 'payment-agent', version: '0.1.0' });
  });

  expressApp.get('/.well-known/agent.json', (_req, res) => {
    res.json(paymentAgentCard);
  });

  expressApp.listen(PORT, HOST, () => {
    console.log(`[PaymentAgent] Server started on http://${HOST}:${PORT}`);
    console.log(`[PaymentAgent] Agent Card: http://localhost:${PORT}/.well-known/agent.json`);
    console.log(`[PaymentAgent] Health: http://localhost:${PORT}/health`);
    console.log(`[PaymentAgent] x402 Facilitator: http://localhost:${PORT}/x402/supported`);
    console.log('[PaymentAgent] Press Ctrl+C to stop the server');
    console.log('');
    console.log('[PaymentAgent] Available skills:');
    paymentAgentCard.skills?.forEach((skill) => {
      console.log(`  - ${skill.id}: ${skill.name}`);
    });
  });
}

main().catch((error) => {
  console.error('[PaymentAgent] Failed to start:', error);
  process.exit(1);
});
