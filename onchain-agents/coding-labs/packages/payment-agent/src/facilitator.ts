/**
 * x402 Facilitator Proxy
 *
 * Implements x402 facilitator endpoints (/verify, /settle, /supported)
 * by proxying to a configurable upstream facilitator service.
 *
 * Default upstream: https://x402.org/facilitator (Base Sepolia testnet)
 * Alternative: https://facilitator.primev.xyz (Ethereum mainnet with preconfirmations)
 */

import type { Request, Response, Router } from 'express';
import express from 'express';

// Upstream facilitator URL - configurable via env or config.toml
const FACILITATOR_URL = process.env.X402_FACILITATOR_URL || 'https://x402.org/facilitator';
const DEFAULT_NETWORK = process.env.X402_DEFAULT_NETWORK || 'eip155:84532';

// Supported networks and their USDC contract addresses
const SUPPORTED_NETWORKS: Record<string, { name: string; usdcAddress: string; facilitatorUrl: string }> = {
  'eip155:84532': {
    name: 'Base Sepolia (Testnet)',
    usdcAddress: '0x036CbD53842c5426634e7929541eC2318f3dCF7e',
    facilitatorUrl: 'https://x402.org/facilitator',
  },
  'eip155:8453': {
    name: 'Base Mainnet',
    usdcAddress: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
    facilitatorUrl: 'https://x402.org/facilitator',
  },
  'eip155:1': {
    name: 'Ethereum Mainnet',
    usdcAddress: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
    facilitatorUrl: 'https://facilitator.primev.xyz',
  },
};

/**
 * Proxy a request to the upstream facilitator
 */
async function proxyToFacilitator(
  endpoint: string,
  body: unknown,
  network?: string
): Promise<{ status: number; data: unknown }> {
  // Determine which facilitator to use based on network
  const networkId = network || DEFAULT_NETWORK;
  const networkConfig = SUPPORTED_NETWORKS[networkId];
  const facilitatorUrl = networkConfig?.facilitatorUrl || FACILITATOR_URL;

  const url = `${facilitatorUrl}${endpoint}`;
  console.log(`[PaymentAgent:Facilitator] Proxying to ${url}`);

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(30000),
    });

    const data = await response.json();
    return { status: response.status, data };
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    console.error(`[PaymentAgent:Facilitator] Proxy error:`, error);
    return {
      status: 502,
      data: { error: 'facilitator_unavailable', message: `Failed to reach upstream facilitator: ${message}` },
    };
  }
}

/**
 * Create Express router with x402 facilitator endpoints
 */
export function createFacilitatorRouter(): Router {
  const router = express.Router();

  // Parse JSON bodies for facilitator routes
  router.use(express.json());

  /**
   * POST /x402/verify — Verify a payment payload
   *
   * Proxies the verification request to the upstream facilitator.
   * Body should contain: { paymentPayload, paymentRequirements }
   */
  router.post('/x402/verify', async (req: Request, res: Response) => {
    console.log('[PaymentAgent:Facilitator] POST /x402/verify');

    const { paymentPayload, paymentRequirements } = req.body;
    if (!paymentPayload || !paymentRequirements) {
      res.status(400).json({
        error: 'invalid_request',
        message: 'Request body must include paymentPayload and paymentRequirements',
      });
      return;
    }

    // Extract network from payment payload if available
    const network = paymentPayload?.network || paymentRequirements?.network;

    const result = await proxyToFacilitator('/verify', req.body, network);
    res.status(result.status).json(result.data);
  });

  /**
   * POST /x402/settle — Settle a payment
   *
   * Proxies the settlement request to the upstream facilitator.
   * Body should contain: { paymentPayload, paymentRequirements }
   */
  router.post('/x402/settle', async (req: Request, res: Response) => {
    console.log('[PaymentAgent:Facilitator] POST /x402/settle');

    const { paymentPayload, paymentRequirements } = req.body;
    if (!paymentPayload || !paymentRequirements) {
      res.status(400).json({
        error: 'invalid_request',
        message: 'Request body must include paymentPayload and paymentRequirements',
      });
      return;
    }

    const network = paymentPayload?.network || paymentRequirements?.network;

    const result = await proxyToFacilitator('/settle', req.body, network);
    res.status(result.status).json(result.data);
  });

  /**
   * GET /x402/supported — List supported networks and schemes
   */
  router.get('/x402/supported', (_req: Request, res: Response) => {
    console.log('[PaymentAgent:Facilitator] GET /x402/supported');

    const networks = Object.entries(SUPPORTED_NETWORKS).map(([id, config]) => ({
      network: id,
      name: config.name,
      scheme: 'exact',
      asset: 'USDC',
      assetAddress: config.usdcAddress,
      facilitatorUrl: config.facilitatorUrl,
    }));

    res.json({
      defaultNetwork: DEFAULT_NETWORK,
      supportedSchemes: ['exact'],
      supportedNetworks: networks,
      facilitatorUrl: FACILITATOR_URL,
    });
  });

  return router;
}

export { SUPPORTED_NETWORKS, FACILITATOR_URL, DEFAULT_NETWORK };
