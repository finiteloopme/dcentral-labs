/**
 * x402 Payment Protocol Types
 *
 * Shared types used by the store agent and payment agent
 * for x402 protocol-based payments.
 */

/**
 * A payment option accepted by a seller
 */
export interface PaymentOption {
  /** Payment scheme (e.g., "exact") */
  scheme: string;
  /** Network identifier in CAIP-2 format (e.g., "eip155:84532") */
  network: string;
  /** Price as human-readable string (e.g., "$2.50") */
  price: string;
  /** Seller's wallet address to receive payment */
  payTo: string;
  /** Asset contract address (e.g., USDC) */
  asset?: string;
}

/**
 * x402 PaymentRequired response
 */
export interface PaymentRequired {
  /** List of accepted payment options */
  accepts: PaymentOption[];
  /** Description of what is being paid for */
  description: string;
  /** MIME type of the response */
  mimeType?: string;
}

/**
 * Order information from the store agent
 */
export interface OrderInfo {
  /** Unique order identifier */
  orderId: string;
  /** Item being purchased */
  item: {
    id: string;
    name: string;
    priceUSDC: string;
  };
  /** x402 payment requirements */
  paymentRequired: PaymentRequired;
  /** Order status */
  status: 'pending_payment' | 'paid' | 'confirmed' | 'cancelled';
}

/**
 * Result of a payment settlement
 */
export interface PaymentResult {
  /** Whether the payment was successful */
  success: boolean;
  /** Transaction hash (if settled) */
  txHash?: string;
  /** Network the payment was settled on */
  network?: string;
  /** Error message (if failed) */
  error?: string;
}
