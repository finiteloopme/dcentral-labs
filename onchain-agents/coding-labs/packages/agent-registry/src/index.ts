/**
 * Agent Registry Service
 *
 * A lightweight service that provides agent discovery for A2A clients.
 * Reads agent configuration from the central config.toml.
 *
 * Endpoints:
 *   GET /agents  - List all enabled agents
 *   GET /health  - Health check
 */

import { serve } from '@hono/node-server';
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import {
  loadConfigFile,
  getEnabledAgents,
  getAllAgents,
  getServiceConfig,
  findConfigPath,
} from '@coding-labs/shared/config';
import type { AgentRegistryResponse } from '@coding-labs/shared/config';

const app = new Hono();

// Middleware
app.use('*', cors());
app.use('*', logger());

// Load configuration
let configPath: string | null = null;
try {
  configPath = findConfigPath();
  console.log(`[AgentRegistry] Using config: ${configPath}`);
} catch (error) {
  console.error('[AgentRegistry] Failed to find config.toml:', error);
}

/**
 * GET /agents - List all enabled agents
 */
app.get('/agents', (c) => {
  try {
    if (!configPath) {
      return c.json({ error: 'Configuration not loaded' }, 500);
    }

    const config = loadConfigFile(configPath);
    const agents = getEnabledAgents(config);

    const response: AgentRegistryResponse = {
      agents,
      version: config.meta.version,
      updated: config.meta.updated,
    };

    return c.json(response);
  } catch (error) {
    console.error('[AgentRegistry] Error fetching agents:', error);
    return c.json({ error: 'Failed to fetch agents' }, 500);
  }
});

/**
 * GET /agents/all - List all agents (including disabled)
 */
app.get('/agents/all', (c) => {
  try {
    if (!configPath) {
      return c.json({ error: 'Configuration not loaded' }, 500);
    }

    const config = loadConfigFile(configPath);
    const agents = getAllAgents(config);

    const response: AgentRegistryResponse = {
      agents,
      version: config.meta.version,
      updated: config.meta.updated,
    };

    return c.json(response);
  } catch (error) {
    console.error('[AgentRegistry] Error fetching agents:', error);
    return c.json({ error: 'Failed to fetch agents' }, 500);
  }
});

/**
 * GET /health - Health check
 */
app.get('/health', (c) => {
  return c.json({
    status: 'healthy',
    service: 'agent-registry',
    version: '0.1.0',
    configLoaded: configPath !== null,
  });
});

// Get port from environment or config
const PORT = parseInt(
  process.env.AGENT_REGISTRY_PORT || process.env.PORT || '4000',
  10
);
const HOST = process.env.AGENT_REGISTRY_HOST || process.env.HOST || 'localhost';

console.log(`[AgentRegistry] Starting Agent Registry...`);

serve(
  {
    fetch: app.fetch,
    port: PORT,
    hostname: HOST,
  },
  (info) => {
    console.log(
      `[AgentRegistry] Server started on http://${HOST}:${info.port}`
    );
    console.log(`[AgentRegistry] Endpoints:`);
    console.log(`  GET /agents  - List enabled agents`);
    console.log(`  GET /health  - Health check`);
    console.log(`[AgentRegistry] Press Ctrl+C to stop`);
  }
);
