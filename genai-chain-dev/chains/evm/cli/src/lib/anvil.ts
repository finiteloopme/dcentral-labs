/**
 * Anvil local node management
 */

import { spawn, ChildProcess } from 'node:child_process';
import { readFileSync, writeFileSync, existsSync, unlinkSync } from 'node:fs';
import { join } from 'node:path';
import { homedir } from 'node:os';
import type { ChainConfig } from './config.js';

export interface AnvilOptions {
  port?: number;
  accounts?: number;
  balance?: string;
  blockTime?: number;
  forkUrl?: string;
  forkBlockNumber?: number;
}

export interface AnvilStatus {
  running: boolean;
  pid?: number;
  port?: number;
  rpcUrl?: string;
}

const DEFAULT_PORT = 8545;
const DEFAULT_ACCOUNTS = 10;
const DEFAULT_BALANCE = '10000';

function getPidFile(config: ChainConfig): string {
  return join(homedir(), '.config', config.cliName, 'anvil.pid');
}

function getLogFile(config: ChainConfig): string {
  return join(homedir(), '.config', config.cliName, 'anvil.log');
}

/**
 * Start Anvil local node
 */
export async function startAnvil(
  config: ChainConfig,
  options: AnvilOptions = {}
): Promise<AnvilStatus> {
  const status = await getAnvilStatus(config);
  if (status.running) {
    throw new Error(`Anvil is already running on port ${status.port} (PID: ${status.pid})`);
  }

  const port = options.port || DEFAULT_PORT;
  const accounts = options.accounts || DEFAULT_ACCOUNTS;
  const balance = options.balance || DEFAULT_BALANCE;

  const args: string[] = [
    '--port', String(port),
    '--accounts', String(accounts),
    '--balance', balance,
  ];

  if (options.blockTime !== undefined && options.blockTime > 0) {
    args.push('--block-time', String(options.blockTime));
  }

  if (options.forkUrl) {
    args.push('--fork-url', options.forkUrl);
    if (options.forkBlockNumber) {
      args.push('--fork-block-number', String(options.forkBlockNumber));
    }
  }

  // Start anvil in background
  const logFile = getLogFile(config);
  const child = spawn('anvil', args, {
    detached: true,
    stdio: ['ignore', 'pipe', 'pipe'],
  });

  // Save PID
  const pidFile = getPidFile(config);
  writeFileSync(pidFile, JSON.stringify({
    pid: child.pid,
    port,
    startedAt: new Date().toISOString(),
  }));

  // Collect initial output
  let logContent = '';
  child.stdout?.on('data', (data) => {
    logContent += data.toString();
    writeFileSync(logFile, logContent);
  });
  child.stderr?.on('data', (data) => {
    logContent += data.toString();
    writeFileSync(logFile, logContent);
  });

  child.unref();

  // Wait for anvil to start
  await waitForAnvil(port);

  return {
    running: true,
    pid: child.pid,
    port,
    rpcUrl: `http://127.0.0.1:${port}`,
  };
}

/**
 * Stop Anvil local node
 */
export async function stopAnvil(config: ChainConfig): Promise<void> {
  const status = await getAnvilStatus(config);
  if (!status.running || !status.pid) {
    throw new Error('Anvil is not running');
  }

  try {
    process.kill(status.pid, 'SIGTERM');
  } catch {
    // Process might already be dead
  }

  // Remove PID file
  const pidFile = getPidFile(config);
  if (existsSync(pidFile)) {
    unlinkSync(pidFile);
  }
}

/**
 * Get Anvil status
 */
export async function getAnvilStatus(config: ChainConfig): Promise<AnvilStatus> {
  const pidFile = getPidFile(config);
  
  if (!existsSync(pidFile)) {
    return { running: false };
  }

  try {
    const content = readFileSync(pidFile, 'utf-8');
    const data = JSON.parse(content);
    
    // Check if process is still running
    try {
      process.kill(data.pid, 0);
      return {
        running: true,
        pid: data.pid,
        port: data.port,
        rpcUrl: `http://127.0.0.1:${data.port}`,
      };
    } catch {
      // Process is not running, clean up
      unlinkSync(pidFile);
      return { running: false };
    }
  } catch {
    return { running: false };
  }
}

/**
 * Get Anvil logs
 */
export function getAnvilLogs(config: ChainConfig, lines?: number): string {
  const logFile = getLogFile(config);
  if (!existsSync(logFile)) {
    return '';
  }
  
  const content = readFileSync(logFile, 'utf-8');
  if (lines) {
    return content.split('\n').slice(-lines).join('\n');
  }
  return content;
}

/**
 * Wait for Anvil to be ready
 */
async function waitForAnvil(port: number, timeout = 10000): Promise<void> {
  const start = Date.now();
  
  while (Date.now() - start < timeout) {
    try {
      const response = await fetch(`http://127.0.0.1:${port}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ jsonrpc: '2.0', method: 'eth_chainId', params: [], id: 1 }),
      });
      if (response.ok) return;
    } catch {
      // Not ready yet
    }
    await new Promise(resolve => setTimeout(resolve, 200));
  }
  
  throw new Error('Anvil failed to start within timeout');
}
