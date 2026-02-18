import type { AgentCard } from '@a2a-js/sdk';

const PORT = process.env.SONIC_AGENT_PORT || 4002;
const HOST = process.env.SONIC_AGENT_HOST || 'localhost';

/**
 * Sonic Agent Card
 *
 * Defines the agent's capabilities, skills, and metadata for A2A discovery.
 */
export const sonicAgentCard: AgentCard = {
  name: 'Sonic Agent',
  description:
    'AI agent specialized for Sonic blockchain development - a high-performance EVM L1 with 400,000 TPS and sub-second finality. ' +
    'Generate and deploy Solidity contracts, earn 90% of gas fees with FeeM.',
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
        'Generate Solidity smart contracts for Sonic. Supports ERC-20, ERC-721, and custom contracts.',
      tags: ['solidity', 'smart-contract', 'code-generation', 'sonic', 'evm'],
      examples: [
        'Create an ERC-20 token for Sonic',
        'Generate a simple NFT contract',
        'Build a staking contract',
      ],
      inputModes: ['text'],
      outputModes: ['text', 'file'],
    },
    {
      id: 'compile',
      name: 'Compile Contract',
      description:
        'Compile Solidity source code using Foundry Forge. Returns ABI and bytecode.',
      tags: ['compile', 'build', 'solidity', 'forge', 'foundry'],
      examples: ['Compile this contract', 'Build my Solidity code'],
      inputModes: ['text', 'file'],
      outputModes: ['text', 'file'],
    },
    {
      id: 'deploy',
      name: 'Deploy Contract',
      description:
        'Deploy a contract to Sonic. Uses local Anvil fork by default for testing.',
      tags: ['deploy', 'publish', 'mainnet', 'fork', 'anvil'],
      examples: ['Deploy this contract', 'Deploy to Sonic'],
      inputModes: ['text', 'file'],
      outputModes: ['text'],
    },
    {
      id: 'call',
      name: 'Call Contract',
      description: 'Call a view/pure function on a deployed contract.',
      tags: ['call', 'read', 'view', 'query', 'contract'],
      examples: ['Get balance of 0x...', 'Call totalSupply on 0x...'],
      inputModes: ['text'],
      outputModes: ['text'],
    },
    {
      id: 'tx-status',
      name: 'Transaction Status',
      description:
        'Check the status of a transaction. Returns status, gas used, and logs.',
      tags: ['transaction', 'status', 'receipt', 'tx'],
      examples: ['Check status of 0x...', 'What happened to tx 0x...'],
      inputModes: ['text'],
      outputModes: ['text'],
    },
    {
      id: 'feem-info',
      name: 'FeeM Information',
      description:
        'Learn about Fee Monetization on Sonic - earn 90% of gas fees your contracts generate.',
      tags: ['feem', 'fees', 'monetization', 'rewards', 'earnings'],
      examples: [
        'How does FeeM work?',
        'How do I register for fee monetization?',
      ],
      inputModes: ['text'],
      outputModes: ['text'],
    },
  ],
  supportsAuthenticatedExtendedCard: false,
};
