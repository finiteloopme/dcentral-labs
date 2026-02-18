/**
 * Resource registration for the Midnight MCP server.
 *
 * Exposes static reference data as MCP resources:
 *  - midnight://networks       - Available networks with endpoints
 *  - midnight://compatibility  - Component compatibility matrix
 *  - midnight://docker-images  - Docker images for local infrastructure
 */

import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import type { MidnightMCPConfig } from '../config.js';
import { NETWORKS, COMPATIBILITY_MATRIX, DOCKER_IMAGES } from '../config.js';

export function registerResources(
  server: McpServer,
  _config: MidnightMCPConfig
): void {
  // --- midnight://networks ---
  server.resource(
    'networks',
    'midnight://networks',
    {
      description:
        'Available Midnight networks with RPC, Indexer, Proof Server, and Faucet endpoints',
      mimeType: 'application/json',
    },
    async () => ({
      contents: [
        {
          uri: 'midnight://networks',
          mimeType: 'application/json',
          text: JSON.stringify(NETWORKS, null, 2),
        },
      ],
    })
  );

  // --- midnight://compatibility ---
  server.resource(
    'compatibility',
    'midnight://compatibility',
    {
      description:
        'Midnight component compatibility matrix (Ledger 7.0.0 / Compatibility v1.0). ' +
        'Source: https://docs.midnight.network/next/relnotes/overview#compatibility-matrix',
      mimeType: 'application/json',
    },
    async () => ({
      contents: [
        {
          uri: 'midnight://compatibility',
          mimeType: 'application/json',
          text: JSON.stringify(
            {
              release: 'Compatibility v1.0',
              source:
                'https://docs.midnight.network/next/relnotes/overview#compatibility-matrix',
              components: COMPATIBILITY_MATRIX,
              environments: ['preview', 'preprod', 'local'],
              releaseNotes: {
                ledger:
                  'https://github.com/midnightntwrk/midnight-ledger/releases/tag/ledger-7.0.0',
                node: 'https://github.com/midnightntwrk/midnight-node/releases/tag/node-0.20.0',
                indexer:
                  'https://github.com/midnightntwrk/midnight-indexer/releases/tag/v3.0.0',
                midnightJs:
                  'https://github.com/midnightntwrk/midnight-js/releases/tag/v3.0.0',
                compactDevTools:
                  'https://github.com/midnightntwrk/compact/releases/tag/compact-v0.4.0',
                dappConnectorApi:
                  'https://github.com/midnightntwrk/midnight-dapp-connector-api/releases/tag/v4.0.0',
              },
            },
            null,
            2
          ),
        },
      ],
    })
  );

  // --- midnight://docker-images ---
  server.resource(
    'docker-images',
    'midnight://docker-images',
    {
      description:
        'Docker images for running Midnight infrastructure locally (Proof Server, Indexer, Node)',
      mimeType: 'application/json',
    },
    async () => ({
      contents: [
        {
          uri: 'midnight://docker-images',
          mimeType: 'application/json',
          text: JSON.stringify(
            {
              images: DOCKER_IMAGES,
              usage: {
                standaloneDevnet: {
                  command: 'docker compose --profile midnight-local up -d',
                  description:
                    'Start a standalone local Midnight devnet with node, indexer, and proof server. ' +
                    'Uses CFG_PRESET=dev on the node for an isolated chain with genesis-minted tokens. ' +
                    'No Cardano dependency, no faucet needed.',
                  ports: { node: 9944, indexer: 8088, proofServer: 6300 },
                },
                proofServer: {
                  command: `docker run -p 6300:6300 ${DOCKER_IMAGES.proofServer}`,
                  port: 6300,
                  description:
                    'ZK proof generation server. Required for all deployments and local testing.',
                },
                indexer: {
                  command: `docker run -p 8088:8088 ${DOCKER_IMAGES.indexer}`,
                  port: 8088,
                  description:
                    'Combined indexer (chain + wallet + API) with embedded storage. ' +
                    'Requires a running Midnight node via APP__INFRA__NODE__URL.',
                },
                node: {
                  command: `docker run -p 9944:9944 -e CFG_PRESET=dev ${DOCKER_IMAGES.node}`,
                  port: 9944,
                  description:
                    'Standalone Midnight node. Set CFG_PRESET=dev for an isolated local chain. ' +
                    'Genesis-minted tokens are available immediately, no faucet required.',
                },
                toolkit: {
                  command: `docker run ${DOCKER_IMAGES.toolkit} version`,
                  description:
                    'Midnight Node Toolkit CLI. Used for wallet management, contract deployment, ' +
                    'and transaction generation. Version-aligned with node.',
                },
              },
            },
            null,
            2
          ),
        },
      ],
    })
  );
}
