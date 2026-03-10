/**
 * x402 Buyer-Side Client Utilities
 *
 * Handles the buyer side of the x402 protocol:
 * - Parsing PaymentRequired responses
 * - Constructing payment payloads
 * - Managing payment state
 */

import { SUPPORTED_NETWORKS } from './facilitator.js';

// x402 Protocol Types (inline instead of @x402/core dependency)

export interface PaymentOption {
  scheme: string;
  network: string;
  price: string;
  payTo: string;
  asset?: string;
}

export interface PaymentRequired {
  accepts: PaymentOption[];
  description: string;
  mimeType?: string;
}

export interface PaymentPayload {
  scheme: string;
  network: string;
  payload: {
    signature: string;
    authorization: {
      from: string;
      to: string;
      value: string;
      validAfter: string;
      validBefore: string;
      nonce: string;
    };
  };
}

export interface SettlementResult {
  success: boolean;
  txHash?: string;
  network?: string;
  error?: string;
  message?: string;
}

// In-memory payment tracking
const paymentHistory = new Map<string, {
  orderId?: string;
  paymentOption: PaymentOption;
  status: 'pending' | 'verified' | 'settled' | 'failed';
  txHash?: string;
  createdAt: string;
  settledAt?: string;
}>();

export function getPaymentRecord(paymentId: string) {
  return paymentHistory.get(paymentId);
}

export function getAllPayments() {
  return Array.from(paymentHistory.entries()).map(([id, record]) => ({
    paymentId: id,
    ...record,
  }));
}

/**
 * Parse payment requirements from a store agent's purchase response
 */
export function parsePaymentRequirements(text: string): {
  orderId?: string;
  paymentRequired?: PaymentRequired;
} | null {
  try {
    // Try to find JSON in the text
    const jsonMatch = text.match(/\{[\s\S]*"paymentRequired"[\s\S]*\}/);
    if (jsonMatch) {
      const parsed = JSON.parse(jsonMatch[0]);
      return {
        orderId: parsed.orderId,
        paymentRequired: parsed.paymentRequired,
      };
    }

    // Try to extract from markdown-formatted output
    const orderIdMatch = text.match(/ord_[a-z0-9]+/i);
    const networkMatch = text.match(/\*\*Network:\*\*\s*(\S+)/);
    const payToMatch = text.match(/\*\*Pay To:\*\*\s*`?(0x[a-fA-F0-9]+)`?/);
    const assetMatch = text.match(/\*\*Asset \(USDC\):\*\*\s*`?(0x[a-fA-F0-9]+)`?/);
    const amountMatch = text.match(/\*\*Amount:\*\*\s*(\d+)\s*\((\d+\.?\d*) USDC\)/);
    const priceMatch = text.match(/\*\*Price:\*\*\s*\$?(\d+\.?\d*)\s*USDC/);

    if (payToMatch) {
      return {
        orderId: orderIdMatch?.[0],
        paymentRequired: {
          accepts: [{
            scheme: 'exact',
            network: networkMatch?.[1] || 'eip155:84532',
            price: priceMatch ? `$${priceMatch[1]}` : (amountMatch ? `$${amountMatch[2]}` : '$0'),
            payTo: payToMatch[1],
            asset: assetMatch?.[1],
          }],
          description: `Payment for order ${orderIdMatch?.[0] || 'unknown'}`,
        },
      };
    }

    return null;
  } catch {
    return null;
  }
}

/**
 * Create a payment record for tracking
 */
export function createPaymentRecord(
  paymentId: string,
  paymentOption: PaymentOption,
  orderId?: string
): void {
  paymentHistory.set(paymentId, {
    orderId,
    paymentOption,
    status: 'pending',
    createdAt: new Date().toISOString(),
  });
}

/**
 * Update payment record status
 */
export function updatePaymentRecord(
  paymentId: string,
  status: 'pending' | 'verified' | 'settled' | 'failed',
  txHash?: string
): void {
  const record = paymentHistory.get(paymentId);
  if (record) {
    record.status = status;
    if (txHash) record.txHash = txHash;
    if (status === 'settled' || status === 'failed') {
      record.settledAt = new Date().toISOString();
    }
  }
}

/**
 * Format supported networks info for display
 */
export function formatSupportedNetworks(networks: Record<string, { name: string; usdcAddress: string; facilitatorUrl: string }>): string {
  let output = '## 🌐 Supported Networks\n\n';
  output += '| Network | Name | USDC Contract | Facilitator |\n';
  output += '|---------|------|---------------|-------------|\n';

  for (const [id, config] of Object.entries(networks)) {
    output += `| \`${id}\` | ${config.name} | \`${config.usdcAddress}\` | ${config.facilitatorUrl} |\n`;
  }

  output += '\n### Supported Schemes\n- **exact** — Exact payment amount in USDC\n';
  output += '\n### How It Works\n';
  output += '1. Request a purchase from the **@store** agent\n';
  output += '2. Tell the **@payment** agent to pay for the order\n';
  output += '3. The payment agent handles x402 verification and settlement\n';
  output += '4. Confirm the purchase with the **@store** agent\n';

  return output;
}

// Re-export SUPPORTED_NETWORKS for convenience
export { SUPPORTED_NETWORKS };
