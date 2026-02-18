/**
 * FeeM Information Skill
 *
 * Returns information about Sonic's Fee Monetization program.
 *
 * TODO: Implement actual FeeM integration for registration and rewards checking.
 */

import type { Message } from '@a2a-js/sdk';
import type { WalletContext } from '@coding-labs/shared';
import type { SkillEvent } from './index.js';

/**
 * Return FeeM information and guidance.
 */
export async function* feemInfoSkill(
  _userMessage: Message,
  _walletContext?: WalletContext,
  _sessionId?: string
): AsyncGenerator<SkillEvent, void, unknown> {
  yield { type: 'status', message: 'Loading FeeM information...' };

  const feemInfo = `# FeeM (Fee Monetization)

Sonic's unique developer incentive: **earn 90% of gas fees** your contracts generate!

## How It Works

1. **Deploy** your contract to Sonic mainnet
2. **Register** at https://feem.soniclabs.com/
3. **Earn** fees automatically from every transaction

## Key Points

| Feature | Value |
|---------|-------|
| Developer Share | 90% |
| Validator Share | 10% |
| Claiming | No deadline |
| Rewards | Processed after each epoch |

## For Upgradeable Contracts

- Register the **proxy address** (not implementation)
- Gas consumed via delegate-call is attributed to proxy
- Works with all standard proxy patterns (UUPS, Transparent, etc.)

## Registration Checklist

- [ ] Contract deployed to Sonic mainnet
- [ ] Contract verified on SonicScan
- [ ] Ownership/control verified
- [ ] Application submitted at feem.soniclabs.com

## Useful Links

- **Dashboard**: https://feem.soniclabs.com/
- **Documentation**: https://docs.soniclabs.com/funding/fee-monetization
- **Explorer**: https://sonicscan.org

---

> **Note**: FeeM integration (registration, rewards checking) is planned for a future update.
> Currently, you need to manually register at the FeeM dashboard.
`;

  yield {
    type: 'artifact',
    name: 'feem-info.md',
    content: feemInfo,
    mimeType: 'text/markdown',
  };

  yield {
    type: 'result',
    data: {
      topic: 'FeeM (Fee Monetization)',
      developerShare: '90%',
      validatorShare: '10%',
      dashboard: 'https://feem.soniclabs.com/',
      docs: 'https://docs.soniclabs.com/funding/fee-monetization',
      status: 'TODO - Manual registration required',
    },
  };
}
