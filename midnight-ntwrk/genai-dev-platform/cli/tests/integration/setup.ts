/**
 * Integration Test Setup
 * 
 * Loads environment configuration from .env in project root and provides
 * utilities for checking service availability.
 */

import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

// Get directory of this file
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Project root is 3 levels up from tests/integration/
const PROJECT_ROOT = path.resolve(__dirname, '..', '..', '..');

/**
 * Service configuration loaded from .env
 */
export interface ServiceConfig {
  nodeUrl: string;
  indexerUrl: string;
  proofServerUrl: string;
  toolkitPath: string;
}

/**
 * Load .env file and parse key=value pairs
 */
function loadEnvFile(envPath: string): Record<string, string> {
  if (!fs.existsSync(envPath)) {
    return {};
  }
  
  const content = fs.readFileSync(envPath, 'utf-8');
  const env: Record<string, string> = {};
  
  for (const line of content.split('\n')) {
    const trimmed = line.trim();
    // Skip comments and empty lines
    if (!trimmed || trimmed.startsWith('#')) continue;
    
    const eqIndex = trimmed.indexOf('=');
    if (eqIndex === -1) continue;
    
    const key = trimmed.slice(0, eqIndex).trim();
    let value = trimmed.slice(eqIndex + 1).trim();
    
    // Remove quotes if present
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    
    env[key] = value;
  }
  
  return env;
}

/**
 * Get service configuration from .env file in project root
 */
export function getServiceConfig(): ServiceConfig {
  const envPath = path.join(PROJECT_ROOT, '.env');
  const env = loadEnvFile(envPath);
  
  // Also check process.env for overrides
  const nodeUrl = process.env.MIDNIGHT_NODE_URL || env.MIDNIGHT_NODE_URL || 'ws://localhost:9944';
  const indexerUrl = process.env.INDEXER_URL || env.INDEXER_URL || 'http://localhost:8088';
  const proofServerUrl = process.env.PROOF_SERVER_URL || env.PROOF_SERVER_URL || 'http://localhost:6300';
  const toolkitPath = process.env.MIDNIGHT_TOOLKIT_PATH || env.MIDNIGHT_TOOLKIT_PATH || '/usr/local/bin/midnight-node-toolkit';
  
  return {
    nodeUrl,
    indexerUrl,
    proofServerUrl,
    toolkitPath,
  };
}

/**
 * Check if the Midnight node is reachable
 */
export async function checkNodeAvailable(config: ServiceConfig): Promise<boolean> {
  try {
    // Convert ws:// to http:// for health check
    const httpUrl = config.nodeUrl.replace('ws://', 'http://').replace('wss://', 'https://');
    const response = await fetch(`${httpUrl}/health`, {
      signal: AbortSignal.timeout(5000),
    });
    return response.ok;
  } catch {
    return false;
  }
}

/**
 * Check if the indexer is reachable
 */
export async function checkIndexerAvailable(config: ServiceConfig): Promise<boolean> {
  try {
    // Ensure we have the GraphQL path
    let url = config.indexerUrl;
    if (!url.includes('/api/')) {
      url = url.replace(/\/$/, '') + '/api/v3/graphql';
    }
    
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ query: '{ block { height } }' }),
      signal: AbortSignal.timeout(5000),
    });
    
    if (!response.ok) return false;
    
    const data = await response.json();
    return data.data?.block?.height !== undefined;
  } catch {
    return false;
  }
}

/**
 * Check if the toolkit binary is available
 */
export async function checkToolkitAvailable(config: ServiceConfig): Promise<boolean> {
  try {
    await fs.promises.access(config.toolkitPath, fs.constants.X_OK);
    return true;
  } catch {
    return false;
  }
}

/**
 * Check if all required services are available
 */
export async function checkServicesAvailable(): Promise<{
  available: boolean;
  node: boolean;
  indexer: boolean;
  toolkit: boolean;
  config: ServiceConfig;
}> {
  const config = getServiceConfig();
  
  const [node, indexer, toolkit] = await Promise.all([
    checkNodeAvailable(config),
    checkIndexerAvailable(config),
    checkToolkitAvailable(config),
  ]);
  
  return {
    available: node && indexer && toolkit,
    node,
    indexer,
    toolkit,
    config,
  };
}

/**
 * Get the project root directory
 */
export function getProjectRoot(): string {
  return PROJECT_ROOT;
}

/**
 * Get the CLI source directory
 */
export function getCliDir(): string {
  return path.join(PROJECT_ROOT, 'cli');
}
