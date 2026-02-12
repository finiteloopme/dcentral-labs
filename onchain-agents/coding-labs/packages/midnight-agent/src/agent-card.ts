/**
 * Midnight Agent Card
 *
 * Defines the A2A agent card for the Midnight Network agent.
 * Skills are focused on Compact smart contract development and
 * privacy-preserving blockchain operations.
 */

import type { AgentCard } from '@a2a-js/sdk';

const PORT = process.env.MIDNIGHT_AGENT_PORT || 4003;
const HOST = process.env.MIDNIGHT_AGENT_HOST || 'localhost';

export const midnightAgentCard: AgentCard = {
  name: 'Midnight Agent',
  description:
    'AI agent for Midnight Network - a privacy-preserving blockchain using zero-knowledge proofs. ' +
    'Generates Compact smart contracts with selective disclosure and ZK proof capabilities. ' +
    'Uses Compact language version 0.20 (compiler 0.28.0).',
  url: `http://${HOST}:${PORT}/`,
  protocolVersion: '0.3.0',
  provider: {
    organization: 'Coding Labs',
    url: 'https://github.com/dcentral-labs/onchain-agents',
  },
  version: '0.1.0',
  capabilities: {
    streaming: true,
    pushNotifications: false,
    stateTransitionHistory: true,
  },
  defaultInputModes: ['text'],
  defaultOutputModes: ['text', 'file'],
  skills: [
    {
      id: 'compact-gen',
      name: 'Compact Code Generation',
      description:
        'Generate Compact smart contracts for Midnight Network. ' +
        'Supports ledger state, circuits, witnesses, and ZK-proof patterns. ' +
        'Uses Compact language version 0.20 (compiler 0.28.0).',
      tags: ['compact', 'code-generation', 'smart-contract', 'zk', 'privacy'],
      examples: [
        'Create a simple counter contract',
        'Generate a voting contract with private ballots',
        'Create a token contract with confidential balances',
        'Build a contract with time-locked access control',
      ],
      inputModes: ['text'],
      outputModes: ['text', 'file'],
    },
    {
      id: 'compile',
      name: 'Compile Compact Contract',
      description:
        'Compile Compact source code to ZK circuits using the Compact compiler (v0.28.0). ' +
        'Outputs JavaScript implementation and TypeScript declarations.',
      tags: ['compile', 'compact', 'zk-circuits'],
      examples: [
        'Compile my counter.compact file',
        'Check if this Compact code compiles',
      ],
      inputModes: ['text', 'file'],
      outputModes: ['text'],
    },
    {
      id: 'deploy',
      name: 'Deploy Contract',
      description:
        'Deploy a compiled Compact contract to Midnight Network (Preview or Preprod). ' +
        'Returns contract address and deployment transaction.',
      tags: ['deploy', 'transaction', 'midnight'],
      examples: [
        'Deploy the counter contract to Preview network',
        'Deploy my voting contract to Preprod',
      ],
      inputModes: ['text', 'file'],
      outputModes: ['text'],
    },
    {
      id: 'call',
      name: 'Call Circuit',
      description:
        'Execute a circuit on a deployed contract with ZK proof generation. ' +
        'Handles witness execution, proof creation, and transaction submission.',
      tags: ['call', 'circuit', 'zk-proof', 'transaction'],
      examples: [
        'Call the increment circuit on my counter contract',
        'Execute the vote circuit with my private ballot',
      ],
      inputModes: ['text'],
      outputModes: ['text'],
    },
    {
      id: 'query-state',
      name: 'Query Ledger State',
      description:
        'Query public ledger state from deployed contracts via the Midnight Indexer (GraphQL). ' +
        'Returns current on-chain state values.',
      tags: ['query', 'state', 'indexer', 'graphql'],
      examples: [
        'Get the current counter value',
        'Query the voting results from my contract',
      ],
      inputModes: ['text'],
      outputModes: ['text'],
    },
    {
      id: 'private-state',
      name: 'Manage Private State',
      description:
        'Manage local private state for Midnight contracts. ' +
        'Private state is stored encrypted on the user device and used in witness execution.',
      tags: ['private-state', 'witness', 'encryption'],
      examples: [
        'Show my private voting key',
        'Initialize private state for the token contract',
      ],
      inputModes: ['text'],
      outputModes: ['text'],
    },
  ],
  supportsAuthenticatedExtendedCard: false,
};
