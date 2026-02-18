/**
 * Midnight Node Toolkit Client
 *
 * Wrapper for calling midnight-node-toolkit CLI from Node.js.
 * All blockchain operations go through the toolkit binary.
 *
 * The toolkit binary is copied from the official Docker image at build time
 * and is version-aligned with the Midnight node.
 */

import { execFile } from 'child_process';
import { promisify } from 'util';
import { join } from 'path';
import { mkdir, readFile, rm } from 'fs/promises';
import { randomUUID } from 'crypto';
import { tmpdir } from 'os';
import { MIDNIGHT_VERSION, NETWORKS } from './config.js';

const execFileAsync = promisify(execFile);

// Configuration from environment
const TOOLKIT_BIN = process.env.TOOLKIT_BIN || 'midnight-node-toolkit';
const INTENTS_DIR =
  process.env.INTENTS_DIR || join(tmpdir(), 'midnight-intents');

// Timeout for toolkit operations (2 minutes for proof generation)
const TOOLKIT_TIMEOUT_MS = 120000;

// -----------------------------------------------------------------------------
// Types
// -----------------------------------------------------------------------------

export interface ToolkitResult {
  success: boolean;
  stdout: string;
  stderr: string;
  error?: string;
}

export interface ToolkitVersion {
  node: string;
  ledger: string;
  compactc: string;
}

export interface WalletAddress {
  address: string;
  network: string;
}

export interface WalletState {
  coins: unknown;
  utxos: unknown[];
  dustUtxos: unknown[];
}

export interface DeployResult {
  success: boolean;
  contractAddress: string;
  txId: string;
  message: string;
  error?: string;
}

export interface CallResult {
  success: boolean;
  txId: string;
  message: string;
  error?: string;
}

// -----------------------------------------------------------------------------
// Core Functions
// -----------------------------------------------------------------------------

/**
 * Execute the toolkit binary with given arguments.
 */
export async function runToolkit(args: string[]): Promise<ToolkitResult> {
  try {
    const { stdout, stderr } = await execFileAsync(TOOLKIT_BIN, args, {
      timeout: TOOLKIT_TIMEOUT_MS,
      maxBuffer: 10 * 1024 * 1024, // 10MB buffer for large outputs
    });
    return { success: true, stdout, stderr };
  } catch (error) {
    const err = error as {
      stdout?: string;
      stderr?: string;
      message: string;
      code?: string | number;
    };

    // Check if it's a timeout
    if (err.code === 'ETIMEDOUT') {
      return {
        success: false,
        stdout: err.stdout || '',
        stderr: err.stderr || '',
        error: `Toolkit operation timed out after ${TOOLKIT_TIMEOUT_MS}ms`,
      };
    }

    return {
      success: false,
      stdout: err.stdout || '',
      stderr: err.stderr || '',
      error: err.message,
    };
  }
}

/**
 * Get toolkit version information.
 * Output format: "Node: X.Y.Z\nLedger: A.B.C\nCompactc: D.E.F"
 */
export async function getVersion(): Promise<ToolkitVersion> {
  const result = await runToolkit(['version']);

  if (!result.success) {
    throw new Error(`Failed to get toolkit version: ${result.error}`);
  }

  const nodeMatch = result.stdout.match(/Node:\s*(\S+)/);
  const ledgerMatch = result.stdout.match(/Ledger:\s*(\S+)/);
  const compactcMatch = result.stdout.match(/Compactc:\s*(\S+)/);

  return {
    node: nodeMatch?.[1] || 'unknown',
    ledger: ledgerMatch?.[1] || 'unknown',
    compactc: compactcMatch?.[1] || 'unknown',
  };
}

/**
 * Validate that toolkit version matches expected version.
 * Logs a warning if versions don't match.
 */
export async function validateVersion(): Promise<boolean> {
  try {
    const version = await getVersion();
    const expected = MIDNIGHT_VERSION;

    if (version.node !== expected) {
      console.warn(
        `⚠️  Toolkit version mismatch! Expected: ${expected}, Got: ${version.node}`
      );
      return false;
    }

    console.log(`✓ Toolkit version validated: ${version.node}`);
    return true;
  } catch (error) {
    console.error('Failed to validate toolkit version:', error);
    return false;
  }
}

// -----------------------------------------------------------------------------
// Wallet Operations
// -----------------------------------------------------------------------------

/**
 * Get wallet address from seed.
 *
 * @param seed - 32-byte hex seed
 * @param network - Network name (undeployed, testnet, preview, preprod)
 * @param options - Address type options
 */
export async function showAddress(
  seed: string,
  network: string,
  options?: {
    shielded?: boolean;
    coinPublic?: boolean;
    dustAddress?: boolean;
  }
): Promise<string> {
  // Map our network names to toolkit network names
  const toolkitNetwork = mapNetworkName(network);

  const args = ['show-address', '--network', toolkitNetwork, '--seed', seed];

  const result = await runToolkit(args);

  if (!result.success) {
    throw new Error(`show-address failed: ${result.error || result.stderr}`);
  }

  // Parse JSON output - show-address returns JSON with multiple address types
  try {
    const addresses = JSON.parse(result.stdout);
    // Return the requested address type, default to unshielded
    if (options?.shielded) return addresses.shielded;
    if (options?.dustAddress) return addresses.dust;
    return addresses.unshielded;
  } catch {
    // If not JSON, return raw output (backwards compat)
    return result.stdout.trim();
  }
}

/**
 * Get wallet state (balances, UTXOs, etc.)
 *
 * @param seed - 32-byte hex seed
 * @param network - Network name
 * @param srcUrl - Node RPC URL to sync from
 */
export async function showWallet(
  seed: string,
  _network: string, // Not used - show-wallet doesn't have --network flag
  srcUrl: string
): Promise<WalletState> {
  const result = await runToolkit([
    'show-wallet',
    '--seed',
    seed,
    '--src-url',
    srcUrl,
  ]);

  if (!result.success) {
    throw new Error(`show-wallet failed: ${result.error || result.stderr}`);
  }

  // Parse JSON output
  try {
    return JSON.parse(result.stdout);
  } catch {
    throw new Error(`Failed to parse wallet state: ${result.stdout}`);
  }
}

// -----------------------------------------------------------------------------
// Contract Operations (Custom Contracts via contract-custom)
// -----------------------------------------------------------------------------
//
// NOTE: contract-simple is intentionally NOT supported.
// It's a Midnight internal test contract requiring MIDNIGHT_LEDGER_TEST_STATIC_DIR
// environment variable pointing to test data files from the node image.
// For real contracts, use deployContract/callContract with compiled Compact contracts.
//

/**
 * Parameters for deploying a custom contract.
 */
export interface ContractDeployParams {
  /** Path to compactc output directory containing key files */
  compiledContractDir: string;
  /** Path to deploy intent .mn file */
  intentFile: string;
  /** Optional funding wallet seed (defaults to genesis seed) */
  fundingSeed?: string;
}

/**
 * Parameters for calling a custom contract.
 */
export interface ContractCallParams {
  /** Path to compactc output directory containing key files */
  compiledContractDir: string;
  /** Path to call intent .mn file */
  intentFile: string;
  /** Optional funding wallet seed (defaults to genesis seed) */
  fundingSeed?: string;
}

/**
 * Deploy a compiled Compact contract using contract-custom.
 *
 * @param params - Deployment parameters (compiledContractDir, intentFile, fundingSeed)
 * @param nodeRpcUrl - Node RPC URL
 * @param proofServerUrl - Proof server URL for ZK proof generation
 */
export async function deployContract(
  params: ContractDeployParams,
  nodeRpcUrl: string,
  proofServerUrl: string
): Promise<DeployResult> {
  const { compiledContractDir, intentFile, fundingSeed } = params;
  const seed = fundingSeed || GENESIS_WALLET_SEED;

  const args = [
    'generate-txs',
    '--src-url',
    nodeRpcUrl,
    '--dest-url',
    nodeRpcUrl,
    '--proof-server',
    proofServerUrl,
    'contract-custom',
    '--compiled-contract-dir',
    compiledContractDir,
    '--intent-file',
    intentFile,
    '--funding-seed',
    seed,
  ];

  const result = await runToolkit(args);

  if (!result.success) {
    return {
      success: false,
      contractAddress: '',
      txId: '',
      message: 'Deployment failed',
      error: result.error || result.stderr,
    };
  }

  // Parse contract address and txId from output
  const addressMatch = result.stdout.match(
    /Contract(?:\s+Address)?:\s*([a-f0-9]{64})/i
  );
  const txIdMatch = result.stdout.match(
    /(?:Transaction|Tx)(?:\s+ID)?:\s*([a-f0-9]+)/i
  );

  return {
    success: true,
    contractAddress: addressMatch?.[1] || '',
    txId: txIdMatch?.[1] || '',
    message: 'Contract deployed successfully',
  };
}

/**
 * Call a circuit on a deployed contract using contract-custom.
 *
 * @param params - Call parameters (compiledContractDir, intentFile, fundingSeed)
 * @param nodeRpcUrl - Node RPC URL
 * @param proofServerUrl - Proof server URL for ZK proof generation
 */
export async function callContract(
  params: ContractCallParams,
  nodeRpcUrl: string,
  proofServerUrl: string
): Promise<CallResult> {
  const { compiledContractDir, intentFile, fundingSeed } = params;
  const seed = fundingSeed || GENESIS_WALLET_SEED;

  const args = [
    'generate-txs',
    '--src-url',
    nodeRpcUrl,
    '--dest-url',
    nodeRpcUrl,
    '--proof-server',
    proofServerUrl,
    'contract-custom',
    '--compiled-contract-dir',
    compiledContractDir,
    '--intent-file',
    intentFile,
    '--funding-seed',
    seed,
  ];

  const result = await runToolkit(args);

  if (!result.success) {
    return {
      success: false,
      txId: '',
      message: 'Contract call failed',
      error: result.error || result.stderr,
    };
  }

  // Parse txId from output
  const txIdMatch = result.stdout.match(
    /(?:Transaction|Tx)(?:\s+ID)?:\s*([a-f0-9]+)/i
  );

  return {
    success: true,
    txId: txIdMatch?.[1] || '',
    message: 'Contract call executed successfully',
  };
}

// -----------------------------------------------------------------------------
// State Queries
// -----------------------------------------------------------------------------

/**
 * Get contract on-chain state.
 *
 * @param contractAddress - Contract address
 * @param network - Target network
 * @param nodeRpcUrl - Node RPC URL
 */
export async function getContractState(
  contractAddress: string,
  _network: string, // Not used - contract-state doesn't have --network flag
  nodeRpcUrl: string
): Promise<{ success: boolean; state: unknown; error?: string }> {
  await ensureDir(INTENTS_DIR);
  const stateFile = join(INTENTS_DIR, `state-${randomUUID()}.bin`);

  try {
    const result = await runToolkit([
      'contract-state',
      '--src-url',
      nodeRpcUrl,
      '--contract-address',
      contractAddress,
      '--dest-file',
      stateFile,
    ]);

    if (!result.success) {
      return {
        success: false,
        state: null,
        error: result.error || result.stderr,
      };
    }

    // Read state file
    const stateData = await readFile(stateFile);
    return {
      success: true,
      state: stateData.toString('hex'),
    };
  } finally {
    // Cleanup
    await rm(stateFile, { force: true }).catch(() => {});
  }
}

// -----------------------------------------------------------------------------
// Transaction Operations
// -----------------------------------------------------------------------------

/**
 * Send tokens (shielded or unshielded).
 *
 * @param fromSeed - Source wallet seed
 * @param toAddress - Destination address
 * @param amount - Amount to send
 * @param network - Target network
 * @param nodeRpcUrl - Node RPC URL
 * @param options - Additional options
 */
export async function sendTokens(
  fromSeed: string,
  toAddress: string,
  amount: bigint,
  _network: string, // Not used - generate-txs doesn't have --network flag
  nodeRpcUrl: string,
  options?: {
    shielded?: boolean;
    unshielded?: boolean;
  }
): Promise<{ success: boolean; txId: string; error?: string }> {
  const args = [
    'generate-txs',
    '--src-url',
    nodeRpcUrl,
    '--dest-url',
    nodeRpcUrl,
    'single-tx',
    '--source-seed',
    fromSeed,
    '--destination-address',
    toAddress,
  ];

  if (options?.shielded) {
    args.push('--shielded-amount', amount.toString());
  } else {
    args.push('--unshielded-amount', amount.toString());
  }

  const result = await runToolkit(args);

  if (!result.success) {
    return {
      success: false,
      txId: '',
      error: result.error || result.stderr,
    };
  }

  const txIdMatch = result.stdout.match(
    /(?:Transaction|Tx)(?:\s+ID)?:\s*([a-f0-9]+)/i
  );

  return {
    success: true,
    txId: txIdMatch?.[1] || '',
  };
}

// -----------------------------------------------------------------------------
// Helper Functions
// -----------------------------------------------------------------------------

/**
 * Map our network names to toolkit network names.
 * Toolkit uses: undeployed, testnet
 * We use: local, preview, preprod
 */
function mapNetworkName(network: string): string {
  const net = NETWORKS[network];
  if (!net) {
    // If not found, assume it's already a toolkit network name
    return network;
  }
  return net.networkId; // 'undeployed' or 'testnet'
}

/**
 * Ensure a directory exists.
 */
async function ensureDir(dir: string): Promise<void> {
  await mkdir(dir, { recursive: true });
}

/**
 * Genesis wallet seed for local standalone chains.
 * This seed has pre-minted tDUST on CFG_PRESET=dev chains.
 */
export const GENESIS_WALLET_SEED =
  '0000000000000000000000000000000000000000000000000000000000000001';

/**
 * Generate a random 32-byte hex seed.
 */
export function generateWalletSeed(): string {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('');
}

/**
 * Get the node RPC URL for a network.
 */
export function getNodeRpcUrl(network: string): string {
  const net = NETWORKS[network];
  if (!net) {
    throw new Error(`Unknown network: ${network}`);
  }
  return net.nodeRpc;
}
