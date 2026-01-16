/**
 * Base command utilities for building CLI commands
 */

import { Command } from 'commander';
import type { ChainAdapter } from '../interfaces/chain.js';
import { createLogger, type Logger } from '../utils/logger.js';
import { loadChainConfig, type ChainConfig } from '../utils/config.js';

/**
 * CLI builder options
 */
export interface CLIBuilderOptions {
  name: string;
  version: string;
  description: string;
  adapter: ChainAdapter;
}

/**
 * Command context passed to command handlers
 */
export interface CommandContext {
  adapter: ChainAdapter;
  config: ChainConfig;
  logger: Logger;
  program: Command;
}

/**
 * Create a CLI program with the given adapter
 */
export function createCLI(options: CLIBuilderOptions): Command {
  const { name, version, description, adapter } = options;

  const program = new Command()
    .name(name)
    .version(version)
    .description(description);

  // Store adapter in program for commands to access
  program.setOptionValue('adapter', adapter);

  return program;
}

/**
 * Get command context from a Command instance
 */
export function getContext(command: Command): CommandContext {
  // Walk up to root program to get adapter
  let root = command;
  while (root.parent) {
    root = root.parent;
  }

  const adapter = root.getOptionValue('adapter') as ChainAdapter;
  const config = loadChainConfig();
  const verbose = root.opts().verbose as boolean | undefined;
  const logger = createLogger({ verbose });

  return {
    adapter,
    config,
    logger,
    program: root,
  };
}

/**
 * Error handler wrapper for commands
 */
export function handleErrors<T extends unknown[]>(
  fn: (...args: T) => Promise<void>
): (...args: T) => Promise<void> {
  return async (...args: T) => {
    try {
      await fn(...args);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      console.error(`\x1b[31m[ERROR]\x1b[0m ${message}`);
      process.exit(1);
    }
  };
}

/**
 * Add common options to a command
 */
export function addCommonOptions(command: Command): Command {
  return command
    .option('-v, --verbose', 'Enable verbose output')
    .option('--json', 'Output as JSON');
}

/**
 * Output data in JSON or human-readable format
 */
export function output(data: unknown, options: { json?: boolean }): void {
  if (options.json) {
    console.log(JSON.stringify(data, null, 2));
  } else if (typeof data === 'object' && data !== null) {
    // Pretty print object
    for (const [key, value] of Object.entries(data)) {
      console.log(`  ${key}: ${value}`);
    }
  } else {
    console.log(data);
  }
}
