/**
 * request_tokens tool
 *
 * Requests testnet tokens (tDUST) from the Midnight faucet.
 *
 * Note: The faucet provides a web UI but may not have a documented
 * public API. This tool attempts to interact with the faucet
 * programmatically and falls back to providing the faucet URL
 * for manual token requests.
 */

import type { MidnightMCPConfig } from '../config.js';
import { NETWORKS, resolveNetwork } from '../config.js';

export interface FaucetResult {
  success: boolean;
  network: string;
  faucetUrl: string;
  data: unknown;
  errors?: string;
}

/**
 * Request testnet tokens from the Midnight faucet.
 *
 * Currently provides faucet URL guidance since the faucet API
 * may require browser interaction (captcha, etc.).
 */
export async function requestTokens(
  address: string,
  config: MidnightMCPConfig,
  network?: string
): Promise<FaucetResult> {
  const resolvedNetwork = resolveNetwork(config, network);
  const networkConfig = NETWORKS[resolvedNetwork];
  const faucetUrl = networkConfig.faucetUrl;

  // Validate address format
  if (!address || address.length < 10) {
    return {
      success: false,
      network: resolvedNetwork,
      faucetUrl,
      data: null,
      errors:
        'Invalid address. Please provide a valid Midnight wallet address.',
    };
  }

  // Attempt to call faucet API
  try {
    // Try a POST to the faucet with the address
    const response = await fetch(faucetUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ address }),
    });

    if (response.ok) {
      const data = await response.json().catch(() => null);
      return {
        success: true,
        network: resolvedNetwork,
        faucetUrl,
        data: data || {
          message: 'Token request submitted successfully',
          address,
        },
      };
    }

    // If POST fails, the faucet likely requires browser interaction
    return {
      success: false,
      network: resolvedNetwork,
      faucetUrl,
      data: {
        status: 'manual_required',
        message:
          'The faucet requires manual interaction via the web UI. ' +
          'Please visit the faucet URL and paste your address.',
        faucetUrl,
        address,
        instructions: [
          `1. Open ${faucetUrl} in a browser`,
          `2. Paste your address: ${address}`,
          '3. Complete any captcha verification',
          "4. Click 'Request tDUST'",
          '5. Wait a few minutes for tokens to arrive',
        ],
      },
      errors:
        'Faucet API not available for programmatic access. Use the web UI instead.',
    };
  } catch {
    // Network error or faucet unreachable
    return {
      success: false,
      network: resolvedNetwork,
      faucetUrl,
      data: {
        status: 'manual_required',
        message:
          'Could not reach the faucet programmatically. ' +
          'Please visit the faucet URL manually.',
        faucetUrl,
        address,
        instructions: [
          `1. Open ${faucetUrl} in a browser`,
          `2. Paste your address: ${address}`,
          '3. Complete any captcha verification',
          "4. Click 'Request tDUST'",
          '5. Wait a few minutes for tokens to arrive',
        ],
      },
      errors: 'Faucet unreachable. Visit the faucet URL manually.',
    };
  }
}
