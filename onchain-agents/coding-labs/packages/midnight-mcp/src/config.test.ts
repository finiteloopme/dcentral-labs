import { describe, it, expect } from 'vitest';
import {
  loadConfig,
  resolveNetwork,
  getIndexerUrl,
  getProofServerUrl,
  NETWORKS,
  COMPATIBILITY_MATRIX,
  DOCKER_IMAGES,
} from '../src/config.js';

describe('config', () => {
  describe('loadConfig', () => {
    it('returns default configuration', () => {
      const config = loadConfig();
      expect(config.port).toBe(4010);
      expect(config.host).toBe('localhost');
      expect(config.compactBinaryPath).toBe('compact');
      // Default network is now 'local' for container-first approach
      expect(config.defaultNetwork).toBe('local');
      expect(config.proofServerUrl).toBeNull();
    });
  });

  describe('resolveNetwork', () => {
    it('resolves to default network when none specified', () => {
      const config = loadConfig();
      // Default network is now 'local' for container-first approach
      expect(resolveNetwork(config)).toBe('local');
    });

    it('resolves explicit network', () => {
      const config = loadConfig();
      expect(resolveNetwork(config, 'preprod')).toBe('preprod');
    });

    it('throws on unknown network', () => {
      const config = loadConfig();
      expect(() => resolveNetwork(config, 'mainnet')).toThrow(
        'Unknown network'
      );
    });
  });

  describe('getIndexerUrl', () => {
    it('returns default indexer URL for preview', () => {
      const config = loadConfig();
      const url = getIndexerUrl(config, 'preview');
      expect(url).toBe(NETWORKS.preview.indexerGraphql);
      expect(url).toContain('preview.midnight.network');
    });

    it('returns default indexer URL for preprod', () => {
      const config = loadConfig();
      const url = getIndexerUrl(config, 'preprod');
      expect(url).toBe(NETWORKS.preprod.indexerGraphql);
      expect(url).toContain('preprod.midnight.network');
    });

    it('throws on unknown network', () => {
      const config = loadConfig();
      expect(() => getIndexerUrl(config, 'unknown')).toThrow('Unknown network');
    });
  });

  describe('getProofServerUrl', () => {
    it('returns network default when no override', () => {
      const config = loadConfig();
      const url = getProofServerUrl(config, 'preview');
      expect(url).toBe(NETWORKS.preview.proofServer);
    });

    it('returns override when configured', () => {
      const config = loadConfig();
      config.proofServerUrl = 'http://localhost:6300';
      const url = getProofServerUrl(config, 'preview');
      expect(url).toBe('http://localhost:6300');
    });
  });

  describe('NETWORKS', () => {
    it('has preview, preprod, and local', () => {
      expect(Object.keys(NETWORKS)).toEqual(['preview', 'preprod', 'local']);
    });

    it('preview has all required endpoints', () => {
      const preview = NETWORKS.preview;
      expect(preview.nodeRpc).toContain('preview');
      expect(preview.indexerGraphql).toContain('v3/graphql');
      expect(preview.proofServer).toBeDefined();
      expect(preview.faucetUrl).toBeDefined();
    });

    it('preprod has all required endpoints', () => {
      const preprod = NETWORKS.preprod;
      expect(preprod.nodeRpc).toContain('preprod');
      expect(preprod.indexerGraphql).toContain('v3/graphql');
      expect(preprod.proofServer).toBeDefined();
      expect(preprod.faucetUrl).toBeDefined();
    });

    it('local has container endpoints (with env var fallback)', () => {
      const local = NETWORKS.local;
      expect(local.name).toBe('Local (Standalone)');
      // Default to container names; env vars can override to localhost
      expect(local.nodeRpc).toContain('9944');
      expect(local.indexerGraphql).toContain('8088');
      expect(local.proofServer).toContain('6300');
      expect(local.faucetUrl).toBe('');
      expect(local.explorerUrl).toBe('');
    });
  });

  describe('COMPATIBILITY_MATRIX', () => {
    it('has correct versions from docs', () => {
      expect(COMPATIBILITY_MATRIX.version).toBe('0.20.1');
      expect(COMPATIBILITY_MATRIX.ledger).toBe('7.0.0');
      expect(COMPATIBILITY_MATRIX.compactCompiler).toBe('0.28.0');
      expect(COMPATIBILITY_MATRIX.compactLanguage).toBe('0.21');
      expect(COMPATIBILITY_MATRIX.proofServer).toBe('7.0.0');
      expect(COMPATIBILITY_MATRIX.indexer).toBe('3.0.0');
    });
  });

  describe('DOCKER_IMAGES', () => {
    it('has correct image references', () => {
      // Proof server uses its own versioning
      expect(DOCKER_IMAGES.proofServer).toBe(
        'midnightnetwork/proof-server:7.0.0-rc.1'
      );
      // Indexer uses separate versioning (3.0.0)
      expect(DOCKER_IMAGES.indexer).toBe(
        `midnightntwrk/indexer-standalone:${COMPATIBILITY_MATRIX.indexer}`
      );
      // Node and toolkit use same version (0.20.1)
      expect(DOCKER_IMAGES.node).toBe(
        `midnightntwrk/midnight-node:${COMPATIBILITY_MATRIX.version}`
      );
      expect(DOCKER_IMAGES.toolkit).toBe(
        `midnightntwrk/midnight-node-toolkit:${COMPATIBILITY_MATRIX.version}`
      );
    });

    it('node and toolkit use same version, indexer uses separate version', () => {
      expect(DOCKER_IMAGES.node).toContain('0.20.1');
      expect(DOCKER_IMAGES.toolkit).toContain('0.20.1');
      // Indexer uses 3.0.0, not 0.20.1
      expect(DOCKER_IMAGES.indexer).toContain('3.0.0');
    });
  });
});
