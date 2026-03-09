import type { Message } from '@a2a-js/sdk';
import type { WalletContext } from '@coding-labs/shared';
import type { SkillEvent } from './index.js';
import { extractTextFromMessage } from './index.js';
import { findItemByName, findItemById, CATALOG } from '../catalog.js';

export async function* getItemDetail(
  userMessage: Message,
  _walletContext?: WalletContext
): AsyncGenerator<SkillEvent, void, unknown> {
  yield { type: 'status', message: 'Looking up item details...' };

  const text = extractTextFromMessage(userMessage);

  // Try to find the item by name or ID
  let item = findItemByName(text);
  if (!item) {
    // Try to extract item name from common patterns
    const patterns = [
      /(?:tell me about|details? (?:on|for|about)|info (?:on|about)|describe|how much (?:is|does|for)) (?:the |a )?(.+)/i,
      /(?:price of|cost of) (?:the |a )?(.+)/i,
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
    // Try matching against all items
    const lower = text.toLowerCase();
    item = CATALOG.find(i => lower.includes(i.name.toLowerCase()));
  }

  if (!item) {
    yield {
      type: 'error',
      message: `Could not find that item. Try browsing the catalog first with "show me all items" to see available products.`,
    };
    return;
  }

  const detail = `## ${item.name}\n\n` +
    `**ID:** \`${item.id}\`\n` +
    `**Category:** ${item.category}\n` +
    `**Price:** $${item.priceUSDC} USDC\n` +
    `**Status:** ${item.inStock ? '✅ In Stock' : '❌ Out of Stock'}\n\n` +
    `${item.description}\n\n` +
    `_To purchase, say "buy ${item.name}"_`;

  yield {
    type: 'artifact',
    name: 'item-detail.md',
    content: detail,
    mimeType: 'text/markdown',
  };

  yield {
    type: 'result',
    data: { item },
  };
}
