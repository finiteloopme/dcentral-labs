import type { Message } from '@a2a-js/sdk';
import type { WalletContext } from '@coding-labs/shared';
import type { SkillEvent } from './index.js';
import { formatSupportedNetworks, SUPPORTED_NETWORKS } from '../x402-client.js';
import { FACILITATOR_URL, DEFAULT_NETWORK } from '../facilitator.js';

export async function* listSupported(
  _userMessage: Message,
  walletContext?: WalletContext
): AsyncGenerator<SkillEvent, void, unknown> {
  yield { type: 'status', message: 'Fetching supported networks and schemes...' };

  let content = formatSupportedNetworks(SUPPORTED_NETWORKS);

  content += `\n### Current Configuration\n`;
  content += `- **Default Network:** \`${DEFAULT_NETWORK}\`\n`;
  content += `- **Facilitator:** ${FACILITATOR_URL}\n`;
  content += `- **Wallet:** ${walletContext?.connected ? `Connected (${walletContext.address})` : 'Not connected'}\n`;

  yield {
    type: 'artifact',
    name: 'supported-networks.md',
    content,
    mimeType: 'text/markdown',
  };

  const networks = Object.entries(SUPPORTED_NETWORKS).map(([id, config]) => ({
    network: id,
    name: config.name,
    scheme: 'exact',
    asset: 'USDC',
    assetAddress: config.usdcAddress,
  }));

  yield {
    type: 'result',
    data: {
      defaultNetwork: DEFAULT_NETWORK,
      facilitatorUrl: FACILITATOR_URL,
      supportedSchemes: ['exact'],
      networks,
      walletConnected: walletContext?.connected || false,
    },
  };
}
