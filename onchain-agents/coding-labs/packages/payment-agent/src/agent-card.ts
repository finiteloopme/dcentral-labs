import type { AgentCard } from '@a2a-js/sdk';

const PORT = process.env.PAYMENT_AGENT_PORT || 4005;
const HOST = process.env.PAYMENT_AGENT_HOST || 'localhost';

export const paymentAgentCard: AgentCard = {
  name: 'Payment Agent',
  description:
    'x402 payment facilitator and buyer-side agent. Handles USDC payments, verification, and settlement for purchases using the x402 protocol. Supports Base Sepolia (testnet), Base Mainnet, and Ethereum Mainnet.',
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
  defaultOutputModes: ['text'],
  skills: [
    {
      id: 'pay',
      name: 'Pay for Order',
      description:
        'Execute a payment for a store order using the x402 protocol. Handles wallet signing and facilitator settlement.',
      tags: ['payment', 'x402', 'usdc', 'settle', 'buy'],
      examples: [
        'Pay for order ord_abc12345',
        'Complete payment for my notebook purchase',
        'Send USDC payment to the store',
      ],
      inputModes: ['text'],
      outputModes: ['text'],
    },
    {
      id: 'verify-payment',
      name: 'Verify Payment',
      description:
        'Verify a payment payload without settling. Checks network support, address validity, and wallet readiness.',
      tags: ['payment', 'verify', 'validate', 'check'],
      examples: [
        'Can I pay for this order?',
        'Verify payment details for ord_abc12345',
        'Check if this payment will work',
      ],
      inputModes: ['text'],
      outputModes: ['text'],
    },
    {
      id: 'payment-status',
      name: 'Payment Status',
      description:
        'Check the status of a payment or view payment history.',
      tags: ['payment', 'status', 'history', 'receipt'],
      examples: [
        'Check payment status for pay_abc123',
        'Show my payment history',
        'What payments have I made?',
      ],
      inputModes: ['text'],
      outputModes: ['text'],
    },
    {
      id: 'supported',
      name: 'Supported Networks',
      description:
        'List supported blockchain networks, payment schemes, and facilitator information.',
      tags: ['networks', 'supported', 'info', 'help'],
      examples: [
        'What networks do you support?',
        'Which blockchains can I pay on?',
        'Show supported payment methods',
      ],
      inputModes: ['text'],
      outputModes: ['text'],
    },
  ],
  supportsAuthenticatedExtendedCard: false,
};
