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
              environments: ['preview', 'preprod'],
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
                proofServer: {
                  command:
                    'docker run -p 6300:6300 midnightnetwork/proof-server -- midnight-proof-server --network preview',
                  port: 6300,
                  description:
                    'ZK proof generation server. Required for all deployments.',
                },
                indexerStandalone: {
                  command:
                    'docker run -p 8080:8080 midnightntwrk/indexer-standalone:3.0.0',
                  port: 8080,
                  description:
                    'Combined indexer with SQLite DB. Alternative to hosted indexer endpoints.',
                },
                node: {
                  command: 'docker run midnightntwrk/midnight-node:0.20.0',
                  description:
                    'Full Midnight node. Required only for running a local devnet (complex setup).',
                  note: 'Running a local node requires Cardano integration and is not recommended for DApp development. Use Preview/Preprod testnets instead.',
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
