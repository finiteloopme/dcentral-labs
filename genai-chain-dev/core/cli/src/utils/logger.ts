/**
 * Logging utilities with colored output
 */

import chalk from 'chalk';

export type LogLevel = 'debug' | 'info' | 'warn' | 'error' | 'success';

export interface Logger {
  debug(message: string, ...args: unknown[]): void;
  info(message: string, ...args: unknown[]): void;
  warn(message: string, ...args: unknown[]): void;
  error(message: string, ...args: unknown[]): void;
  success(message: string, ...args: unknown[]): void;
  log(message: string, ...args: unknown[]): void;
  table(data: Record<string, unknown>[]): void;
  newline(): void;
}

/**
 * Create a logger instance
 */
export function createLogger(options: { verbose?: boolean } = {}): Logger {
  const { verbose = false } = options;

  return {
    debug(message: string, ...args: unknown[]) {
      if (verbose) {
        console.log(chalk.gray(`[DEBUG] ${message}`), ...args);
      }
    },

    info(message: string, ...args: unknown[]) {
      console.log(chalk.blue('[INFO]'), message, ...args);
    },

    warn(message: string, ...args: unknown[]) {
      console.log(chalk.yellow('[WARN]'), message, ...args);
    },

    error(message: string, ...args: unknown[]) {
      console.error(chalk.red('[ERROR]'), message, ...args);
    },

    success(message: string, ...args: unknown[]) {
      console.log(chalk.green('[SUCCESS]'), message, ...args);
    },

    log(message: string, ...args: unknown[]) {
      console.log(message, ...args);
    },

    table(data: Record<string, unknown>[]) {
      console.table(data);
    },

    newline() {
      console.log('');
    },
  };
}

/**
 * Default logger instance
 */
export const logger = createLogger();

/**
 * Format a value for display
 */
export function formatValue(value: string | number | bigint, decimals = 18): string {
  if (typeof value === 'bigint') {
    const divisor = BigInt(10 ** decimals);
    const integerPart = value / divisor;
    const fractionalPart = value % divisor;
    const fractionalStr = fractionalPart.toString().padStart(decimals, '0').slice(0, 4);
    return `${integerPart}.${fractionalStr}`;
  }
  return String(value);
}

/**
 * Format an address for display (truncated)
 */
export function formatAddress(address: string, chars = 6): string {
  if (address.length <= chars * 2 + 2) return address;
  return `${address.slice(0, chars + 2)}...${address.slice(-chars)}`;
}

/**
 * Print a section header
 */
export function printHeader(title: string): void {
  console.log('');
  console.log(chalk.bold(title));
  console.log(chalk.gray('─'.repeat(title.length)));
}

/**
 * Print a key-value pair
 */
export function printKeyValue(key: string, value: string, indent = 2): void {
  const spaces = ' '.repeat(indent);
  console.log(`${spaces}${chalk.gray(key + ':')} ${value}`);
}
