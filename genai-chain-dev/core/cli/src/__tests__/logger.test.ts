import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { createLogger, formatValue, formatAddress } from '../utils/logger.js';

describe('logger', () => {
  let consoleSpy: ReturnType<typeof vi.spyOn>;
  let consoleErrorSpy: ReturnType<typeof vi.spyOn>;

  beforeEach(() => {
    consoleSpy = vi.spyOn(console, 'log').mockImplementation(() => {});
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    consoleSpy.mockRestore();
    consoleErrorSpy.mockRestore();
  });

  describe('createLogger', () => {
    it('should create a logger with default options', () => {
      const logger = createLogger();
      expect(logger).toBeDefined();
      expect(typeof logger.info).toBe('function');
      expect(typeof logger.error).toBe('function');
      expect(typeof logger.warn).toBe('function');
      expect(typeof logger.success).toBe('function');
      expect(typeof logger.debug).toBe('function');
    });

    it('should log info messages', () => {
      const logger = createLogger();
      logger.info('test message');
      expect(consoleSpy).toHaveBeenCalled();
    });

    it('should log error messages to stderr', () => {
      const logger = createLogger();
      logger.error('error message');
      expect(consoleErrorSpy).toHaveBeenCalled();
    });

    it('should not log debug messages by default', () => {
      const logger = createLogger();
      logger.debug('debug message');
      expect(consoleSpy).not.toHaveBeenCalled();
    });

    it('should log debug messages when verbose is true', () => {
      const logger = createLogger({ verbose: true });
      logger.debug('debug message');
      expect(consoleSpy).toHaveBeenCalled();
    });
  });

  describe('formatValue', () => {
    it('should format bigint with 18 decimals', () => {
      const value = BigInt('1000000000000000000'); // 1 ETH
      const result = formatValue(value, 18);
      expect(result).toBe('1.0000');
    });

    it('should format bigint with fractional part', () => {
      const value = BigInt('1500000000000000000'); // 1.5 ETH
      const result = formatValue(value, 18);
      expect(result).toBe('1.5000');
    });

    it('should format small values', () => {
      const value = BigInt('100000000000000'); // 0.0001 ETH
      const result = formatValue(value, 18);
      expect(result).toBe('0.0001');
    });

    it('should format string values', () => {
      const result = formatValue('123.45', 18);
      expect(result).toBe('123.45');
    });
  });

  describe('formatAddress', () => {
    it('should truncate long addresses', () => {
      const address = '0x1234567890abcdef1234567890abcdef12345678';
      const result = formatAddress(address);
      expect(result).toBe('0x123456...345678');
    });

    it('should not truncate short addresses', () => {
      const address = '0x1234';
      const result = formatAddress(address);
      expect(result).toBe('0x1234');
    });

    it('should respect custom char count', () => {
      const address = '0x1234567890abcdef1234567890abcdef12345678';
      const result = formatAddress(address, 4);
      expect(result).toBe('0x1234...5678');
    });
  });
});
