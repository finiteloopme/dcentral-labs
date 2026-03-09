import type { Message } from '@a2a-js/sdk';
import type { WalletContext } from '@coding-labs/shared';
import type { SkillEvent } from './index.js';
import { extractTextFromMessage } from './index.js';
import { parsePaymentRequirements, SUPPORTED_NETWORKS } from '../x402-client.js';
import { FACILITATOR_URL } from '../facilitator.js';

export async function* verifyPayment(
  userMessage: Message,
  walletContext?: WalletContext
): AsyncGenerator<SkillEvent, void, unknown> {
  yield { type: 'status', message: 'Verifying payment details...' };

  const text = extractTextFromMessage(userMessage);
  const parsed = parsePaymentRequirements(text);

  if (!parsed || !parsed.paymentRequired) {
    yield {
      type: 'error',
      message: 'No payment details found to verify. Please provide the payment requirements from a store purchase.',
    };
    return;
  }

  const paymentOption = parsed.paymentRequired.accepts[0];
  if (!paymentOption) {
    yield { type: 'error', message: 'No accepted payment options found.' };
    return;
  }

  // Verify the payment option is valid
  const checks: { check: string; passed: boolean; detail: string }[] = [];

  // Check network support
  const networkSupported = paymentOption.network in SUPPORTED_NETWORKS;
  checks.push({
    check: 'Network supported',
    passed: networkSupported,
    detail: networkSupported
      ? `${paymentOption.network} (${SUPPORTED_NETWORKS[paymentOption.network]?.name})`
      : `${paymentOption.network} — not in supported networks`,
  });

  // Check scheme
  const schemeSupported = paymentOption.scheme === 'exact';
  checks.push({
    check: 'Scheme supported',
    passed: schemeSupported,
    detail: schemeSupported ? 'exact' : `${paymentOption.scheme} — only "exact" is supported`,
  });

  // Check payTo address
  const validAddress = /^0x[a-fA-F0-9]{40}$/.test(paymentOption.payTo);
  checks.push({
    check: 'Valid payTo address',
    passed: validAddress,
    detail: validAddress ? paymentOption.payTo : 'Invalid Ethereum address format',
  });

  // Check price
  const hasPrice = !!paymentOption.price && paymentOption.price !== '$0';
  checks.push({
    check: 'Valid price',
    passed: hasPrice,
    detail: hasPrice ? paymentOption.price : 'Price is zero or missing',
  });

  // Check wallet
  const walletReady = !!walletContext?.connected;
  checks.push({
    check: 'Wallet connected',
    passed: walletReady,
    detail: walletReady ? `Connected: ${walletContext?.address}` : 'Wallet not connected',
  });

  const allPassed = checks.every(c => c.passed);

  let report = `## 🔍 Payment Verification\n\n`;
  report += `**Order ID:** \`${parsed.orderId || 'N/A'}\`\n`;
  report += `**Overall:** ${allPassed ? '✅ Ready to pay' : '❌ Issues found'}\n\n`;
  report += `| Check | Status | Detail |\n`;
  report += `|-------|--------|--------|\n`;
  checks.forEach(c => {
    report += `| ${c.check} | ${c.passed ? '✅' : '❌'} | ${c.detail} |\n`;
  });
  report += `\n_Facilitator: ${FACILITATOR_URL}_\n`;

  if (allPassed) {
    report += `\n✅ All checks passed. You can proceed with: "pay for order ${parsed.orderId}"`;
  }

  yield {
    type: 'artifact',
    name: 'verification-report.md',
    content: report,
    mimeType: 'text/markdown',
  };

  yield {
    type: 'result',
    data: {
      orderId: parsed.orderId,
      valid: allPassed,
      checks,
    },
  };
}
