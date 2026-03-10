import type { Message } from '@a2a-js/sdk';
import type { WalletContext } from '@coding-labs/shared';
import type { SkillEvent } from './index.js';
import { extractTextFromMessage } from './index.js';
import { CATALOG, getItemsByCategory, searchItems } from '../catalog.js';

export async function* browseCatalog(
  userMessage: Message,
  _walletContext?: WalletContext
): AsyncGenerator<SkillEvent, void, unknown> {
  yield { type: 'status', message: 'Browsing the stationery catalog...' };

  const text = extractTextFromMessage(userMessage).toLowerCase();

  // Check for category filter
  const categories = ['notebooks', 'pens', 'pencils', 'erasers', 'markers', 'paper', 'accessories'];
  let items = CATALOG;
  let filterLabel = 'All Items';

  for (const category of categories) {
    // Match both singular and plural forms
    const singular = category.replace(/s$/, '');
    if (text.includes(category) || text.includes(singular)) {
      items = getItemsByCategory(category);
      filterLabel = `Category: ${category.charAt(0).toUpperCase() + category.slice(1)}`;
      break;
    }
  }

  // If no category match, check for search terms (excluding common words)
  if (items === CATALOG && !text.includes('all') && !text.includes('everything') && !text.includes('catalog') && !text.includes('what do you')) {
    const searchTerms = text.replace(/show|me|list|search|find|for|the|a|an|do|you|have|sell/g, '').trim();
    if (searchTerms.length > 2) {
      const results = searchItems(searchTerms);
      if (results.length > 0) {
        items = results;
        filterLabel = `Search: "${searchTerms.trim()}"`;
      }
    }
  }

  // Format catalog as a readable list
  let catalog = `## 🏪 Stationery Store — ${filterLabel}\n\n`;
  catalog += `| # | Item | Category | Price (USDC) | Status |\n`;
  catalog += `|---|------|----------|--------------|--------|\n`;

  items.forEach((item, index) => {
    const status = item.inStock ? '✅ In Stock' : '❌ Out of Stock';
    catalog += `| ${index + 1} | **${item.name}** | ${item.category} | $${item.priceUSDC} | ${status} |\n`;
  });

  catalog += `\n_${items.length} item(s) found. Say "tell me about [item name]" for details, or "buy [item name]" to purchase._`;

  yield {
    type: 'artifact',
    name: 'catalog.md',
    content: catalog,
    mimeType: 'text/markdown',
  };

  yield {
    type: 'result',
    data: {
      itemCount: items.length,
      filter: filterLabel,
      items: items.map(i => ({ id: i.id, name: i.name, priceUSDC: i.priceUSDC })),
    },
  };
}
