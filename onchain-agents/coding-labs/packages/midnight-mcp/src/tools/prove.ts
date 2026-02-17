/**
 * zk_prove tool
 *
 * Wraps the Midnight Proof Server to generate zero-knowledge proofs.
 *
 * The Proof Server runs as a Docker container (midnightnetwork/proof-server)
 * on port 6300 and provides HTTP endpoints for ZK proof generation.
 *
 * Note: The Proof Server's HTTP API is not extensively documented.
 * The Midnight.js SDK typically handles proof generation internally.
 * This tool provides a lower-level interface for direct proof server
 * interaction when needed.
 */

import type { MidnightMCPConfig } from '../config.js';
import { getProofServerUrl, resolveNetwork } from '../config.js';

export interface ProveResult {
  success: boolean;
  proofServerUrl: string;
  network: string;
  data: unknown;
  errors?: string;
}

/**
 * Check if the Proof Server is reachable and healthy.
 */
export async function checkProofServer(
  config: MidnightMCPConfig,
  network?: string
): Promise<ProveResult> {
  const resolvedNetwork = resolveNetwork(config, network);
  const proofServerUrl = getProofServerUrl(config, resolvedNetwork);

  try {
    // The proof server listens on port 6300 - attempt a health check
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000);

    const response = await fetch(proofServerUrl, {
      signal: controller.signal,
    }).catch(() => null);

    clearTimeout(timeoutId);

    if (response) {
      return {
        success: true,
        proofServerUrl,
        network: resolvedNetwork,
        data: {
          status: 'reachable',
          statusCode: response.status,
          message: `Proof Server at ${proofServerUrl} is reachable`,
        },
      };
    }

    return {
      success: false,
      proofServerUrl,
      network: resolvedNetwork,
      data: null,
      errors: `Proof Server at ${proofServerUrl} is not reachable. Ensure it is running: docker run -p 6300:6300 midnightnetwork/proof-server -- midnight-proof-server --network ${resolvedNetwork}`,
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error';
    return {
      success: false,
      proofServerUrl,
      network: resolvedNetwork,
      data: null,
      errors: `Failed to reach Proof Server: ${errorMessage}`,
    };
  }
}

/**
 * Generate a ZK proof using the Proof Server.
 *
 * Note: This is a placeholder implementation. The Proof Server's HTTP API
 * is typically accessed through the Midnight.js SDK rather than directly.
 * The actual proof generation requires compiled circuit data and witness
 * values in a specific binary format.
 *
 * For now, this tool checks proof server availability and provides
 * guidance on how to use the Midnight.js SDK for proof generation.
 */
export async function generateProof(
  _circuitData: string,
  _witnessData: Record<string, unknown>,
  config: MidnightMCPConfig,
  network?: string
): Promise<ProveResult> {
  const resolvedNetwork = resolveNetwork(config, network);
  const proofServerUrl = getProofServerUrl(config, resolvedNetwork);

  // First check if proof server is available
  const healthCheck = await checkProofServer(config, resolvedNetwork);
  if (!healthCheck.success) {
    return healthCheck;
  }

  // The proof server's HTTP API requires binary-encoded circuit data
  // and witness values. Direct HTTP calls are complex - the recommended
  // approach is to use the Midnight.js SDK which handles serialization.
  return {
    success: false,
    proofServerUrl,
    network: resolvedNetwork,
    data: {
      status: 'not_implemented',
      proofServerAvailable: true,
      guidance: {
        message:
          'Direct proof generation via HTTP requires binary-encoded circuit and witness data. ' +
          'Use the Midnight.js SDK (@midnight-ntwrk/midnight-js-contracts) for proof generation, ' +
          'which handles serialization automatically.',
        proofServerUrl,
        sdkPackage: '@midnight-ntwrk/midnight-js-http-client-proof-provider',
        sdkVersion: '2.0.2',
        example:
          'import { httpClientProofProvider } from "@midnight-ntwrk/midnight-js-http-client-proof-provider";\n' +
          `const proofProvider = httpClientProofProvider("${proofServerUrl}");`,
      },
    },
    errors:
      'Direct proof generation not yet implemented. Use Midnight.js SDK instead.',
  };
}
