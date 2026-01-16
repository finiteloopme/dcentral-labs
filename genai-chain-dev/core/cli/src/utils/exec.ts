/**
 * Command execution utilities
 */

import { spawn, SpawnOptions, ChildProcess } from 'node:child_process';

/**
 * Result of command execution
 */
export interface ExecResult {
  /** Exit code */
  code: number;
  /** Standard output */
  stdout: string;
  /** Standard error */
  stderr: string;
  /** Whether command succeeded (code === 0) */
  success: boolean;
}

/**
 * Options for command execution
 */
export interface ExecOptions {
  /** Working directory */
  cwd?: string;
  /** Environment variables */
  env?: Record<string, string>;
  /** Timeout in milliseconds */
  timeout?: number;
  /** Stream output to console */
  stream?: boolean;
  /** Inherit stdio (for interactive commands) */
  inherit?: boolean;
}

/**
 * Execute a command and return the result
 */
export async function exec(
  command: string,
  args: string[],
  options: ExecOptions = {}
): Promise<ExecResult> {
  return new Promise((resolve, reject) => {
    const { cwd, env, timeout, stream = false, inherit = false } = options;

    const spawnOptions: SpawnOptions = {
      cwd,
      env: { ...process.env, ...env },
      stdio: inherit ? 'inherit' : 'pipe',
      shell: false,
    };

    const child = spawn(command, args, spawnOptions);

    let stdout = '';
    let stderr = '';
    let timeoutId: NodeJS.Timeout | undefined;

    if (timeout) {
      timeoutId = setTimeout(() => {
        child.kill('SIGTERM');
        reject(new Error(`Command timed out after ${timeout}ms`));
      }, timeout);
    }

    if (!inherit && child.stdout && child.stderr) {
      child.stdout.on('data', (data: Buffer) => {
        const text = data.toString();
        stdout += text;
        if (stream) {
          process.stdout.write(text);
        }
      });

      child.stderr.on('data', (data: Buffer) => {
        const text = data.toString();
        stderr += text;
        if (stream) {
          process.stderr.write(text);
        }
      });
    }

    child.on('error', (error) => {
      if (timeoutId) clearTimeout(timeoutId);
      reject(error);
    });

    child.on('close', (code) => {
      if (timeoutId) clearTimeout(timeoutId);
      resolve({
        code: code ?? 1,
        stdout,
        stderr,
        success: code === 0,
      });
    });
  });
}

/**
 * Execute a command with inherited stdio (interactive)
 */
export async function execInteractive(
  command: string,
  args: string[],
  options: Omit<ExecOptions, 'stream' | 'inherit'> = {}
): Promise<ExecResult> {
  return exec(command, args, { ...options, inherit: true });
}

/**
 * Check if a command exists
 */
export async function commandExists(command: string): Promise<boolean> {
  try {
    const result = await exec('which', [command]);
    return result.success;
  } catch {
    return false;
  }
}

/**
 * Spawn a background process
 */
export function spawnBackground(
  command: string,
  args: string[],
  options: ExecOptions = {}
): ChildProcess {
  const { cwd, env } = options;

  const child = spawn(command, args, {
    cwd,
    env: { ...process.env, ...env },
    detached: true,
    stdio: 'ignore',
  });

  child.unref();
  return child;
}

/**
 * Wait for a process to be ready (by checking a port)
 */
export async function waitForPort(
  port: number,
  timeout = 30000,
  interval = 500
): Promise<boolean> {
  const startTime = Date.now();
  
  while (Date.now() - startTime < timeout) {
    try {
      const result = await exec('nc', ['-z', 'localhost', String(port)], { timeout: 1000 });
      if (result.success) return true;
    } catch {
      // Port not ready yet
    }
    await new Promise(resolve => setTimeout(resolve, interval));
  }
  
  return false;
}
