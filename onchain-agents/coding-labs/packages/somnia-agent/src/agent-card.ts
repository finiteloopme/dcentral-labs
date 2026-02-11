import type { AgentCard } from '@a2a-js/sdk';

const PORT = process.env.SOMNIA_AGENT_PORT || 4001;
const HOST = process.env.SOMNIA_AGENT_HOST || 'localhost';

export const somniaAgentCard: AgentCard = {
  name: 'Somnia Agent',
  description:
    'AI agent specialized for Somnia blockchain development - a high-performance EVM L1 with 1M+ TPS and sub-second finality. Generates Solidity contracts optimized for Somnia gas model, deploys contracts, queries on-chain state, and configures Somnia-specific features like Reactivity and Data Streams.',
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
      id: 'solidity-gen',
      name: 'Solidity Contract Generation',
      description:
        'Generate Solidity smart contracts optimized for Somnia gas model. Supports ERC-20, ERC-721, custom contracts, and Somnia-specific patterns.',
      tags: ['solidity', 'smart-contract', 'code-generation', 'somnia', 'evm'],
      examples: [
        'Create an ERC-20 token called SomniaToken with symbol SMT',
        'Generate a simple NFT contract with minting function',
        'Build a staking contract that tracks user deposits',
      ],
      inputModes: ['text'],
      outputModes: ['text', 'file'],
    },
    {
      id: 'deploy',
      name: 'Contract Deployment',
      description:
        'Deploy contracts to Somnia testnet or mainnet. Returns unsigned transaction for user to sign with their wallet.',
      tags: ['deploy', 'transaction', 'somnia', 'blockchain'],
      examples: [
        'Deploy this contract to Somnia testnet',
        'Deploy my ERC-20 token to mainnet',
      ],
      inputModes: ['text', 'file'],
      outputModes: ['text'],
    },
    {
      id: 'tx-status',
      name: 'Transaction Status',
      description:
        'Check the status of a transaction on Somnia. Returns status, block number, gas used, and logs.',
      tags: ['transaction', 'status', 'somnia', 'query'],
      examples: [
        'Check status of transaction 0x123...',
        'What happened to my deployment?',
      ],
      inputModes: ['text'],
      outputModes: ['text'],
    },
    {
      id: 'query-state',
      name: 'On-chain Query',
      description:
        'Query contract state on Somnia. Read balances, ownership, and any public contract data.',
      tags: ['query', 'read', 'somnia', 'blockchain', 'state'],
      examples: [
        'Get the balance of address 0x... from token contract 0x...',
        'What is the total supply of this token?',
        'Who owns NFT #5?',
      ],
      inputModes: ['text'],
      outputModes: ['text'],
    },
    {
      id: 'reactivity-setup',
      name: 'Somnia Reactivity',
      description:
        'Generate code for Somnia Reactivity system - on-chain event subscriptions via precompile at 0x0100. Enables reactive smart contracts.',
      tags: ['reactivity', 'events', 'somnia-specific', 'advanced'],
      examples: [
        'Set up a subscription to Transfer events from a token contract',
        'Create a reactive contract that responds to price updates',
      ],
      inputModes: ['text'],
      outputModes: ['text', 'file'],
    },
    {
      id: 'data-streams',
      name: 'Data Streams',
      description:
        'Generate Somnia Data Streams schemas and TypeScript SDK code. For real-time data without Solidity.',
      tags: ['data-streams', 'schema', 'somnia-specific', 'typescript'],
      examples: [
        'Create a data stream for player positions in a game',
        'Set up a chat message stream',
      ],
      inputModes: ['text'],
      outputModes: ['text', 'file'],
    },
  ],
  supportsAuthenticatedExtendedCard: false,
};
