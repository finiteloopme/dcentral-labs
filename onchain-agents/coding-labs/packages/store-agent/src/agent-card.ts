import type { AgentCard } from '@a2a-js/sdk';

const PORT = process.env.STORE_AGENT_PORT || 4004;
const HOST = process.env.STORE_AGENT_HOST || 'localhost';

export const storeAgentCard: AgentCard = {
  name: 'Store Agent',
  description:
    'Mock stationery web store. Browse a catalog of notebooks, pens, pencils, and accessories. Purchase items using crypto payments via the x402 protocol.',
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
      id: 'browse',
      name: 'Browse Catalog',
      description:
        'Browse and search the stationery catalog. List all items, filter by category, or search by name.',
      tags: ['store', 'catalog', 'browse', 'search', 'stationery'],
      examples: [
        'Show me all items',
        'What notebooks do you have?',
        'List pens',
        'Search for pencils',
        'What do you sell?',
      ],
      inputModes: ['text'],
      outputModes: ['text'],
    },
    {
      id: 'item-detail',
      name: 'Item Details',
      description:
        'Get detailed information about a specific stationery item including price and availability.',
      tags: ['store', 'item', 'detail', 'price'],
      examples: [
        'Tell me about the spiral notebook',
        'How much is the gel pen set?',
        'Details on the leather journal',
      ],
      inputModes: ['text'],
      outputModes: ['text'],
    },
    {
      id: 'purchase',
      name: 'Purchase Item',
      description:
        'Initiate a purchase for a stationery item. Returns order details and x402 payment requirements.',
      tags: ['store', 'buy', 'purchase', 'order', 'x402'],
      examples: [
        'Buy the spiral notebook',
        'I want to purchase the gel pen set',
        'Order a mechanical pencil',
      ],
      inputModes: ['text'],
      outputModes: ['text'],
    },
    {
      id: 'confirm',
      name: 'Confirm Purchase',
      description:
        'Confirm a purchase after payment has been made. Provide the transaction hash to verify payment.',
      tags: ['store', 'confirm', 'order', 'receipt'],
      examples: [
        'Confirm my purchase with tx 0x123...',
        'Verify payment for order ord_abc123',
      ],
      inputModes: ['text'],
      outputModes: ['text'],
    },
  ],
  supportsAuthenticatedExtendedCard: false,
};
