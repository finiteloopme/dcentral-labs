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
import { mkdir, readFile, rm, stat } from 'fs/promises';
import { randomUUID } from 'crypto';
import { tmpdir } from 'os';
import { MIDNIGHT_VERSION, NETWORKS } from './config.js';

const execFileAsync = promisify(execFile);

// Configuration from environment
const TOOLKIT_BIN = process.env.TOOLKIT_BIN || 'midnight-node-toolkit';
const INTENTS_DIR =
  process.env.INTENTS_DIR || join(tmpdir(), 'midnight-intents');
// Path to toolkit-js directory (for running generate-intent)
const TOOLKIT_JS_PATH = process.env.TOOLKIT_JS_PATH || '/toolkit-js';

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
 *
 * @param args - Arguments to pass to the toolkit
 * @param options - Optional settings (cwd, env)
 */
export async function runToolkit(
  args: string[],
  options?: { cwd?: string; env?: Record<string, string> }
): Promise<ToolkitResult> {
  try {
    const execOptions = {
      timeout: TOOLKIT_TIMEOUT_MS,
      maxBuffer: 10 * 1024 * 1024, // 10MB buffer for large outputs
      encoding: 'utf-8' as const,
      ...(options?.cwd ? { cwd: options.cwd } : {}),
      ...(options?.env
        ? { env: { ...process.env, ...options.env } }
        : undefined),
    };
    const { stdout, stderr } = await execFileAsync(
      TOOLKIT_BIN,
      args,
      execOptions
    );
    return { success: true, stdout: stdout || '', stderr: stderr || '' };
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

// -----------------------------------------------------------------------------
// Intent Generation (for custom contract deployment via generate-intent)
// -----------------------------------------------------------------------------

/**
 * Parameters for generating a deploy intent.
 */
export interface GenerateDeployIntentParams {
  /** Path to contract.config.ts file */
  configPath: string;
  /** Wallet coin public key (hex) */
  coinPublic: string;
  /** Output directory for generated files */
  outputDir: string;
  /** Constructor arguments (as strings) */
  constructorArgs?: string[];
  /** Network name (default: undeployed) */
  network?: string;
}

/**
 * Result from generating a deploy intent.
 */
export interface GenerateDeployIntentResult {
  success: boolean;
  intentFile: string;
  privateStateFile: string;
  zswapStateFile: string;
  error?: string;
}

/**
 * Generate a deploy intent using the toolkit's generate-intent deploy command.
 *
 * This creates an intent file (.bin) that can be sent via send-intent.
 *
 * NOTE: The toolkit command runs with cwd=TOOLKIT_JS_PATH for module resolution,
 * but the work directory is in /tmp for Cloud Run compatibility.
 * NODE_PATH is set to /toolkit-js/node_modules in the container environment.
 */
export async function generateDeployIntent(
  params: GenerateDeployIntentParams
): Promise<GenerateDeployIntentResult> {
  const {
    configPath,
    coinPublic,
    outputDir,
    constructorArgs = [],
    network = 'undeployed',
  } = params;

  await ensureDir(outputDir);

  // Create a unique temp directory INSIDE toolkit-js for module resolution
  // The toolkit's TypeScript compilation needs @midnight-ntwrk/* modules
  // which are only resolvable from within the toolkit-js directory tree
  const tempName = `deploy-${randomUUID().slice(0, 8)}`;
  const toolkitWorkDir = join(TOOLKIT_JS_PATH, tempName);

  try {
    // Copy the entire work directory to toolkit-js
    await execFileAsync('cp', ['-r', outputDir, toolkitWorkDir], {
      encoding: 'utf-8',
    });
    // Copy the config file
    await execFileAsync('cp', [configPath, toolkitWorkDir + '/'], {
      encoding: 'utf-8',
    });

    const toolkitConfigPath = join(toolkitWorkDir, 'contract.config.ts');
    const intentFile = join(toolkitWorkDir, 'deploy.bin');
    const privateStateFile = join(toolkitWorkDir, 'private_state.json');
    const zswapStateFile = join(toolkitWorkDir, 'zswap_state.json');

    const args = [
      'generate-intent',
      'deploy',
      '-c',
      toolkitConfigPath,
      '--network',
      network,
      '--coin-public',
      coinPublic,
      '--output-intent',
      intentFile,
      '--output-private-state',
      privateStateFile,
      '--output-zswap-state',
      zswapStateFile,
      ...constructorArgs,
    ];

    console.log(`[toolkit] Running: generate-intent deploy from ${tempName}`);
    const result = await runToolkit(args, { cwd: TOOLKIT_JS_PATH });

    // Check for errors in stdout/stderr even if exit code is 0
    // The toolkit may report errors but still exit with code 0
    const output = result.stdout + result.stderr;
    const hasError =
      output.includes('Error loading configuration') ||
      output.includes('Failed to compile') ||
      output.includes('Cannot find module') ||
      output.includes('ENOENT') ||
      output.includes('not assignable to type');

    if (!result.success || hasError) {
      // Clean up temp directory
      await rm(toolkitWorkDir, { recursive: true, force: true }).catch(
        () => {}
      );
      return {
        success: false,
        intentFile: '',
        privateStateFile: '',
        zswapStateFile: '',
        error: result.error || output || 'Unknown error',
      };
    }

    // Verify the intent file was actually created
    try {
      await stat(intentFile);
    } catch {
      await rm(toolkitWorkDir, { recursive: true, force: true }).catch(
        () => {}
      );
      return {
        success: false,
        intentFile: '',
        privateStateFile: '',
        zswapStateFile: '',
        error: `Intent file not created. Toolkit output: ${output}`,
      };
    }

    // Copy output files back to original output directory
    const finalIntentFile = join(outputDir, 'deploy.bin');
    const finalPrivateStateFile = join(outputDir, 'private_state.json');
    const finalZswapStateFile = join(outputDir, 'zswap_state.json');

    await execFileAsync('cp', [intentFile, finalIntentFile], {
      encoding: 'utf-8',
    });
    await execFileAsync('cp', [privateStateFile, finalPrivateStateFile], {
      encoding: 'utf-8',
    });
    await execFileAsync('cp', [zswapStateFile, finalZswapStateFile], {
      encoding: 'utf-8',
    });

    // Clean up temp directory
    await rm(toolkitWorkDir, { recursive: true, force: true }).catch(() => {});

    return {
      success: true,
      intentFile: finalIntentFile,
      privateStateFile: finalPrivateStateFile,
      zswapStateFile: finalZswapStateFile,
    };
  } catch (err) {
    return {
      success: false,
      intentFile: '',
      privateStateFile: '',
      zswapStateFile: '',
      error: `Failed to generate deploy intent: ${err}`,
    };
  }
}

/**
 * Parameters for sending an intent.
 */
export interface SendIntentParams {
  /** Path to intent file (.bin) */
  intentFile: string;
  /** Path to compiled contract directory */
  compiledContractDir: string;
  /** Optional: output file path for transaction */
  destFile?: string;
  /** Save as bytes (true) or JSON (false) */
  toBytes?: boolean;
  /** Funding seed (default: genesis) */
  fundingSeed?: string;
  /** Node RPC URL for fetching state and sending tx */
  nodeRpcUrl?: string;
  /** Proof server URL for generating ZK proofs */
  proofServerUrl?: string;
}

/**
 * Result from sending an intent.
 */
export interface SendIntentResult {
  success: boolean;
  txFile: string;
  error?: string;
}

/**
 * Send an intent and create a transaction file.
 *
 * This creates a transaction file that can be submitted via generate-txs send.
 */
export async function sendIntent(
  params: SendIntentParams
): Promise<SendIntentResult> {
  const {
    intentFile,
    compiledContractDir,
    destFile,
    toBytes = true,
    fundingSeed = GENESIS_WALLET_SEED,
    nodeRpcUrl,
    proofServerUrl,
  } = params;

  const txFile = destFile || intentFile.replace('.bin', '_tx.mn');

  const args = [
    'send-intent',
    '--intent-file',
    intentFile,
    '--compiled-contract-dir',
    compiledContractDir,
    '--funding-seed',
    fundingSeed,
    '--dest-file',
    txFile,
  ];

  // Add node RPC URL for fetching state (--dest-url conflicts with --dest-file)
  if (nodeRpcUrl) {
    args.push('--src-url', nodeRpcUrl);
  }

  // Add proof server URL for ZK proof generation
  if (proofServerUrl) {
    args.push('--proof-server', proofServerUrl);
  }

  if (toBytes) {
    args.push('--to-bytes');
  }

  console.log(
    `[toolkit] Running: send-intent with args:`,
    args.slice(0, 8).join(' '),
    '...'
  );
  const result = await runToolkit(args);

  if (!result.success) {
    return {
      success: false,
      txFile: '',
      error: result.error || result.stderr,
    };
  }

  return {
    success: true,
    txFile,
  };
}

/**
 * Submit a transaction to the chain.
 */
export async function submitTransaction(
  txFile: string,
  nodeRpcUrl: string
): Promise<{ success: boolean; error?: string }> {
  const args = ['generate-txs', '--src-file', txFile, '-d', nodeRpcUrl, 'send'];

  console.log(`[toolkit] Running: generate-txs send`);
  const result = await runToolkit(args);

  if (!result.success) {
    return {
      success: false,
      error: result.error || result.stderr,
    };
  }

  return { success: true };
}

/**
 * Extract contract address from a deploy transaction file.
 */
export async function extractContractAddress(
  txFile: string
): Promise<{ success: boolean; address: string; error?: string }> {
  const args = ['contract-address', '--src-file', txFile];

  console.log(`[toolkit] Running: contract-address`);
  const result = await runToolkit(args);

  if (!result.success) {
    return {
      success: false,
      address: '',
      error: result.error || result.stderr,
    };
  }

  // Output is the address (possibly with "0x" prefix or raw hex)
  const address = result.stdout.trim().replace(/^0x/i, '');

  return {
    success: true,
    address,
  };
}

/**
 * Get coin public key from a wallet seed.
 */
export async function getCoinPublicKey(
  seed: string,
  network: string
): Promise<string> {
  const toolkitNetwork = mapNetworkName(network);

  const args = [
    'show-address',
    '--network',
    toolkitNetwork,
    '--seed',
    seed,
    '--coin-public',
  ];

  const result = await runToolkit(args);

  if (!result.success) {
    throw new Error(
      `Failed to get coin public key: ${result.error || result.stderr}`
    );
  }

  // Output should be the hex-encoded coin public key
  return result.stdout.trim();
}

/**
 * Parameters for generating a circuit call intent.
 */
export interface GenerateCircuitIntentParams {
  /** Path to contract.config.ts file */
  configPath: string;
  /** Wallet coin public key (hex) */
  coinPublic: string;
  /** Deployed contract address */
  contractAddress: string;
  /** Circuit name to call (e.g., "increment") */
  circuitName: string;
  /** Path to on-chain state file */
  onchainStateFile: string;
  /** Path to private state file */
  privateStateFile: string;
  /** Output directory for generated files */
  outputDir: string;
  /** Circuit call arguments (as strings) */
  args?: string[];
  /** Network name (default: undeployed) */
  network?: string;
  /** Node RPC URL for fetching state */
  nodeRpcUrl?: string;
}

/**
 * Result from generating a circuit intent.
 */
export interface GenerateCircuitIntentResult {
  success: boolean;
  intentFile: string;
  newPrivateStateFile: string;
  error?: string;
}

/**
 * Generate a circuit call intent using the toolkit's generate-intent circuit command.
 *
 * NOTE: Like generateDeployIntent, the toolkit runs with cwd=TOOLKIT_JS_PATH for
 * module resolution, but work directory is in /tmp for Cloud Run compatibility.
 */
export async function generateCircuitIntent(
  params: GenerateCircuitIntentParams
): Promise<GenerateCircuitIntentResult> {
  const {
    configPath,
    coinPublic,
    contractAddress,
    circuitName,
    onchainStateFile,
    privateStateFile,
    outputDir,
    args = [],
    network = 'undeployed',
    nodeRpcUrl,
  } = params;

  await ensureDir(outputDir);

  // Create a unique temp directory INSIDE toolkit-js for module resolution
  // The toolkit's TypeScript compilation needs @midnight-ntwrk/* modules
  // which are only resolvable from within the toolkit-js directory tree
  const tempName = `circuit-${randomUUID().slice(0, 8)}`;
  const toolkitWorkDir = join(TOOLKIT_JS_PATH, tempName);

  try {
    // Copy the entire output directory (which has managed/ folder structure) to toolkit-js
    await execFileAsync('cp', ['-r', outputDir, toolkitWorkDir], {
      encoding: 'utf-8',
    });

    // Copy the config file to the toolkit work directory
    await execFileAsync('cp', [configPath, toolkitWorkDir + '/'], {
      encoding: 'utf-8',
    });

    // Copy on-chain state file
    await execFileAsync('cp', [onchainStateFile, toolkitWorkDir + '/'], {
      encoding: 'utf-8',
    });

    // Copy private state file
    await execFileAsync('cp', [privateStateFile, toolkitWorkDir + '/'], {
      encoding: 'utf-8',
    });

    // Set up paths relative to toolkit work directory
    const toolkitConfigPath = join(toolkitWorkDir, 'contract.config.ts');
    const toolkitOnchainStateFile = join(
      toolkitWorkDir,
      onchainStateFile.split('/').pop()!
    );
    const toolkitPrivateStateFile = join(
      toolkitWorkDir,
      privateStateFile.split('/').pop()!
    );

    const intentFile = join(toolkitWorkDir, `${circuitName}.bin`);
    const newPrivateStateFile = join(
      toolkitWorkDir,
      `${circuitName}_private_state.json`
    );
    const zswapStateFile = join(
      toolkitWorkDir,
      `${circuitName}_zswap_state.json`
    );

    const cmdArgs = [
      'generate-intent',
      'circuit',
      '-c',
      toolkitConfigPath,
      '--network',
      network,
      '--coin-public',
      coinPublic,
      '--contract-address',
      contractAddress,
      '--input-onchain-state',
      toolkitOnchainStateFile,
      '--input-private-state',
      toolkitPrivateStateFile,
      '--output-intent',
      intentFile,
      '--output-private-state',
      newPrivateStateFile,
      '--output-zswap-state',
      zswapStateFile,
      circuitName,
      ...args,
    ];

    // Add src-url if provided (for fetching state)
    if (nodeRpcUrl) {
      cmdArgs.splice(2, 0, '-s', nodeRpcUrl);
    }

    console.log(
      `[toolkit] Running: generate-intent circuit ${circuitName} from ${tempName}`
    );
    const result = await runToolkit(cmdArgs, { cwd: TOOLKIT_JS_PATH });

    // Check for errors in stdout/stderr even if exit code is 0
    const output = result.stdout + result.stderr;
    const hasError =
      output.includes('Error loading configuration') ||
      output.includes('Failed to compile') ||
      output.includes('Cannot find module') ||
      output.includes('ENOENT') ||
      output.includes('not assignable to type');

    if (!result.success || hasError) {
      // Keep temp directory for debugging
      console.error(
        `[toolkit] Circuit intent generation failed. Work dir: ${toolkitWorkDir}`
      );
      return {
        success: false,
        intentFile: '',
        newPrivateStateFile: '',
        error: result.error || output || 'Unknown error',
      };
    }

    // Verify the intent file was actually created
    try {
      await stat(intentFile);
    } catch {
      console.error(
        `[toolkit] Intent file not created. Work dir: ${toolkitWorkDir}`
      );
      return {
        success: false,
        intentFile: '',
        newPrivateStateFile: '',
        error: `Intent file not created. Toolkit output: ${output}`,
      };
    }

    // Copy output files back to original output directory
    const finalIntentFile = join(outputDir, `${circuitName}.bin`);
    const finalNewPrivateStateFile = join(
      outputDir,
      `${circuitName}_private_state.json`
    );
    const finalZswapStateFile = join(
      outputDir,
      `${circuitName}_zswap_state.json`
    );

    await execFileAsync('cp', [intentFile, finalIntentFile], {
      encoding: 'utf-8',
    });
    await execFileAsync('cp', [newPrivateStateFile, finalNewPrivateStateFile], {
      encoding: 'utf-8',
    });
    await execFileAsync('cp', [zswapStateFile, finalZswapStateFile], {
      encoding: 'utf-8',
    });

    // Clean up temp directory
    await rm(toolkitWorkDir, { recursive: true, force: true }).catch(() => {});

    return {
      success: true,
      intentFile: finalIntentFile,
      newPrivateStateFile: finalNewPrivateStateFile,
    };
  } catch (err) {
    return {
      success: false,
      intentFile: '',
      newPrivateStateFile: '',
      error: `Failed to generate circuit intent: ${err}`,
    };
  }
}

/**
 * Fetch contract on-chain state and save to file.
 */
export async function fetchContractState(
  contractAddress: string,
  nodeRpcUrl: string,
  destFile: string
): Promise<{ success: boolean; error?: string }> {
  await ensureDir(join(destFile, '..'));

  const args = [
    'contract-state',
    '--src-url',
    nodeRpcUrl,
    '--contract-address',
    contractAddress,
    '--dest-file',
    destFile,
  ];

  console.log(`[toolkit] Running: contract-state`);
  const result = await runToolkit(args);

  if (!result.success) {
    return {
      success: false,
      error: result.error || result.stderr,
    };
  }

  return { success: true };
}
