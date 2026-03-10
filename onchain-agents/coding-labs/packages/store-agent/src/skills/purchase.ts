import { v4 as uuidv4 } from 'uuid';
import type { Message } from '@a2a-js/sdk';
import type { WalletContext } from '@coding-labs/shared';
import type { SkillEvent } from './index.js';
import { extractTextFromMessage } from './index.js';
import { findItemByName, findItemById, CATALOG } from '../catalog.js';

// x402 payment configuration defaults
// These can be overridden via config.toml / environment variables
const X402_NETWORK = process.env.X402_DEFAULT_NETWORK || 'eip155:84532'; // Base Sepolia
const STORE_WALLET = process.env.X402_STORE_WALLET || '0x0000000000000000000000000000000000000000';

// USDC contract addresses per network
const USDC_ADDRESSES: Record<string, string> = {
  'eip155:84532': '0x036CbD53842c5426634e7929541eC2318f3dCF7e',  // Base Sepolia
  'eip155:8453': '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',   // Base Mainnet
  'eip155:1': '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',      // Ethereum Mainnet
};

// Simple in-memory order store
const orders = new Map<string, { itemId: string; itemName: string; priceUSDC: string; priceRaw: string; status: string; createdAt: string }>();

export function getOrder(orderId: string) {
  return orders.get(orderId);
}

export function updateOrderStatus(orderId: string, status: string) {
  const order = orders.get(orderId);
  if (order) {
    order.status = status;
  }
}

export async function* purchaseItem(
  userMessage: Message,
  walletContext?: WalletContext
): AsyncGenerator<SkillEvent, void, unknown> {
  yield { type: 'status', message: 'Processing your purchase request...' };

  const text = extractTextFromMessage(userMessage);

  // Find the item
  let item = findItemByName(text);
  if (!item) {
    const patterns = [
      /(?:buy|purchase|order|i want|i'd like) (?:the |a |an )?(.+)/i,
      /(?:add) (?:the |a |an )?(.+?)(?:\s+to cart)?$/i,
    ];

    for (const pattern of patterns) {
      const match = text.match(pattern);
      if (match) {
        item = findItemByName(match[1].trim());
        if (item) break;
        item = findItemById(match[1].trim());
        if (item) break;
      }
    }
  }

  if (!item) {
    const lower = text.toLowerCase();
    item = CATALOG.find(i => lower.includes(i.name.toLowerCase()));
  }

  if (!item) {
    yield {
      type: 'error',
      message: 'Could not find that item. Please browse the catalog first with "show me all items" and then say "buy [item name]".',
    };
    return;
  }

  if (!item.inStock) {
    yield {
      type: 'error',
      message: `Sorry, **${item.name}** is currently out of stock.`,
    };
    return;
  }

  // Create order
  const orderId = `ord_${uuidv4().slice(0, 8)}`;
  orders.set(orderId, {
    itemId: item.id,
    itemName: item.name,
    priceUSDC: item.priceUSDC,
    priceRaw: item.priceRaw,
    status: 'pending_payment',
    createdAt: new Date().toISOString(),
  });

  const usdcAddress = USDC_ADDRESSES[X402_NETWORK] || USDC_ADDRESSES['eip155:84532'];

  // Build x402 PaymentRequired response
  const paymentRequired = {
    accepts: [
      {
        scheme: 'exact',
        network: X402_NETWORK,
        price: `$${item.priceUSDC}`,
        payTo: STORE_WALLET,
        asset: usdcAddress,
      },
    ],
    description: `Purchase: ${item.name}`,
    mimeType: 'application/json',
  };

  const orderSummary = `## 🛒 Order Created\n\n` +
    `**Order ID:** \`${orderId}\`\n` +
    `**Item:** ${item.name}\n` +
    `**Price:** $${item.priceUSDC} USDC\n` +
    `**Status:** ⏳ Pending Payment\n\n` +
    `### Payment Details (x402)\n\n` +
    `- **Network:** ${X402_NETWORK}\n` +
    `- **Scheme:** exact\n` +
    `- **Pay To:** \`${STORE_WALLET}\`\n` +
    `- **Asset (USDC):** \`${usdcAddress}\`\n` +
    `- **Amount:** ${item.priceRaw} (${item.priceUSDC} USDC)\n\n` +
    (walletContext?.connected
      ? `✅ Wallet connected: \`${walletContext.address}\`\n\n`
      : `⚠️ Please connect your wallet to proceed with payment.\n\n`) +
    `_To complete payment, tell the **@payment** agent: "pay for order ${orderId}"_\n` +
    `_After payment, come back and say: "confirm order ${orderId} with tx 0x..."_`;

  yield {
    type: 'artifact',
    name: 'order.md',
    content: orderSummary,
    mimeType: 'text/markdown',
  };

  yield {
    type: 'result',
    data: {
      orderId,
      item: { id: item.id, name: item.name, priceUSDC: item.priceUSDC },
      paymentRequired,
      status: 'pending_payment',
    },
  };
}
