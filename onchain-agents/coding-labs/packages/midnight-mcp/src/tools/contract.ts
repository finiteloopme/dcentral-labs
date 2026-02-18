/**
 * Contract tools for the Midnight MCP server.
 *
 * Provides tools for deploying and calling compiled Compact contracts
 * using the toolkit's generate-intent + send-intent flow.
 *
 * Deploy flow:
 *   1. Write artifacts to temp directory
 *   2. Generate contract.config.ts from artifacts
 *   3. Generate deploy intent via toolkit
 *   4. Send intent to create transaction
 *   5. Submit transaction to chain
 *   6. Extract contract address
 *
 * Call flow:
 *   1. Fetch on-chain state
 *   2. Load private state from cache
 *   3. Generate circuit intent via toolkit
 *   4. Send intent to create transaction
 *   5. Update cached private state
 */

import { mkdir, writeFile, readFile, copyFile } from 'fs/promises';
import { join } from 'path';
import { randomUUID } from 'crypto';
import { tmpdir } from 'os';

import type { MidnightMCPConfig } from '../config.js';
import {
  resolveNetwork,
  getNodeRpcUrl as getNodeRpcUrlConfig,
  getProofServerUrl,
} from '../config.js';
import {
  GENESIS_WALLET_SEED,
  getCoinPublicKey,
  generateDeployIntent,
  sendIntent,
  submitTransaction,
  extractContractAddress,
  generateCircuitIntent,
  fetchContractState,
} from '../toolkit-client.js';
import { generateContractConfig } from './config-generator.js';
import { getWalletSeed } from './wallet.js';

// -----------------------------------------------------------------------------
// Types
// -----------------------------------------------------------------------------

/**
 * Artifact from compiled contract (from compact_compile tool).
 */
export interface Artifact {
  filename: string;
  content: string;
  mimeType?: string;
}

export interface DeployParams {
  /** Compiled artifacts from compact_compile */
  artifacts: Artifact[];
  /** Contract name */
  contractName: string;
  /** Constructor arguments (as JSON values) */
  constructorArgs?: unknown[];
  /** Target network */
  network?: string;
  /** Initial private state (optional, will be inferred if not provided) */
  initialPrivateState?: Record<string, unknown>;
}

export interface DeployResult {
  success: boolean;
  network: string;
  contractAddress: string;
  txId: string;
  message: string;
  /** Temp directory with artifacts (kept for debugging) */
  workDir?: string;
  errors?: string;
}

export interface CallParams {
  /** Deployed contract address */
  contractAddress: string;
  /** Circuit name to call (e.g., "increment") */
  circuitName: string;
  /** Circuit arguments (as JSON values) */
  args?: unknown[];
  /** Target network */
  network?: string;
}

export interface CallResult {
  success: boolean;
  network: string;
  contractAddress: string;
  txId: string;
  message: string;
  errors?: string;
}

export interface DeployedContract {
  address: string;
  contractName: string;
  compiledDir: string;
  configPath: string;
  privateStateFile: string;
  network: string;
  deployedAt: Date;
  txId: string;
}

// -----------------------------------------------------------------------------
// Configuration
// -----------------------------------------------------------------------------

/** Directory for contract work files */
const CONTRACTS_DIR =
  process.env.CONTRACTS_DIR || join(tmpdir(), 'midnight-contracts');

/** Directory for private state persistence */
const STATE_DIR = process.env.STATE_DIR || '/data/state';

// -----------------------------------------------------------------------------
// In-Memory Contract Cache
// -----------------------------------------------------------------------------

/**
 * Cache of deployed contracts for this session.
 * Key is contract address.
 */
const contractCache = new Map<string, DeployedContract>();

/**
 * Get a cached contract by address.
 */
export function getCachedContract(
  address: string
): DeployedContract | undefined {
  return contractCache.get(address);
}

/**
 * List all cached contracts.
 */
export function listCachedContracts(): DeployedContract[] {
  return Array.from(contractCache.values());
}

/**
 * Clear all cached contracts.
 */
export function clearContractCache(): void {
  contractCache.clear();
}

// -----------------------------------------------------------------------------
// Helper Functions
// -----------------------------------------------------------------------------

/**
 * Write artifacts to a directory structure expected by the toolkit.
 *
 * Expected structure:
 *   workDir/
 *     managed/<contractName>/
 *       contract/
 *         index.cjs (or index.js)
 *         index.d.ts
 *       zkir/
 *         *.zkir
 *       compiler/
 *         contract-info.json
 *       keys/
 *         *.key
 */
async function writeArtifacts(
  artifacts: Artifact[],
  contractName: string,
  workDir: string
): Promise<string> {
  const managedDir = join(workDir, 'managed', contractName);

  // Create subdirectories
  await mkdir(join(managedDir, 'contract'), { recursive: true });
  await mkdir(join(managedDir, 'zkir'), { recursive: true });
  await mkdir(join(managedDir, 'compiler'), { recursive: true });
  await mkdir(join(managedDir, 'keys'), { recursive: true });

  for (const artifact of artifacts) {
    const { filename, content, mimeType } = artifact;

    // Check if this is a base64-encoded binary file
    const isBase64Binary = mimeType?.includes('base64');

    // Determine target path based on filename patterns
    let targetPath: string;

    if (filename.startsWith('contract/') || filename.includes('/contract/')) {
      // Contract JS/TS files
      const basename = filename.split('/').pop()!;
      targetPath = join(managedDir, 'contract', basename);
    } else if (
      filename.startsWith('zkir/') ||
      filename.includes('/zkir/') ||
      filename.endsWith('.zkir')
    ) {
      // ZKIR files
      const basename = filename.split('/').pop()!;
      targetPath = join(managedDir, 'zkir', basename);
    } else if (
      filename.startsWith('compiler/') ||
      filename.includes('/compiler/') ||
      filename === 'contract-info.json'
    ) {
      // Compiler output
      const basename = filename.split('/').pop()!;
      targetPath = join(managedDir, 'compiler', basename);
    } else if (
      filename.startsWith('keys/') ||
      filename.includes('/keys/') ||
      filename.endsWith('.key') ||
      filename.endsWith('.prover') ||
      filename.endsWith('.verifier')
    ) {
      // Key files (prover/verifier for ZK proofs)
      const basename = filename.split('/').pop()!;
      targetPath = join(managedDir, 'keys', basename);
    } else if (
      filename.endsWith('.js') ||
      filename.endsWith('.cjs') ||
      filename.endsWith('.d.ts') ||
      filename.endsWith('.js.map')
    ) {
      // JS files go to contract/
      targetPath = join(managedDir, 'contract', filename);
    } else {
      // Default: put in managed dir root
      targetPath = join(managedDir, filename);
    }

    // Ensure parent directory exists
    await mkdir(join(targetPath, '..'), { recursive: true });

    // Write file - decode base64 for binary files
    if (isBase64Binary) {
      const buffer = Buffer.from(content, 'base64');
      await writeFile(targetPath, buffer);
      console.log(
        `[contract] Wrote binary artifact: ${targetPath} (${buffer.length} bytes)`
      );
    } else {
      await writeFile(targetPath, content, 'utf-8');
      console.log(`[contract] Wrote artifact: ${targetPath}`);
    }
  }

  return managedDir;
}

/**
 * Get or create private state file for a contract.
 */
async function getPrivateStateFile(
  contractAddress: string,
  initialState?: Record<string, unknown>
): Promise<string> {
  await mkdir(STATE_DIR, { recursive: true });
  const stateFile = join(STATE_DIR, `${contractAddress}.json`);

  try {
    // Check if file exists
    await readFile(stateFile, 'utf-8');
  } catch {
    // Create with initial state
    const state = initialState ?? {};
    await writeFile(stateFile, JSON.stringify(state, null, 2), 'utf-8');
  }

  return stateFile;
}

// -----------------------------------------------------------------------------
// Contract Deploy
// -----------------------------------------------------------------------------

/**
 * Deploy a compiled Compact contract to the Midnight network.
 *
 * This uses the full generate-intent + send-intent flow:
 * 1. Write artifacts to temp directory
 * 2. Generate contract.config.ts
 * 3. Generate deploy intent
 * 4. Send intent to create transaction
 * 5. Submit transaction to chain
 * 6. Extract contract address
 */
export async function deployContractFromArtifacts(
  params: DeployParams,
  config: MidnightMCPConfig
): Promise<DeployResult> {
  const {
    artifacts,
    contractName,
    constructorArgs = [],
    network,
    initialPrivateState,
  } = params;

  const resolvedNetwork = resolveNetwork(config, network);
  const nodeRpcUrl = getNodeRpcUrlConfig(config, resolvedNetwork);
  const proofServerUrl = getProofServerUrl(config, resolvedNetwork);

  // Create work directory (kept for debugging)
  const workDir = join(CONTRACTS_DIR, `deploy-${randomUUID()}`);
  await mkdir(workDir, { recursive: true });

  console.log(`[contract] Work directory: ${workDir}`);

  try {
    // Step 1: Write artifacts to managed/<contractName>/
    console.log(`[contract] Step 1: Writing ${artifacts.length} artifacts...`);
    const compiledDir = await writeArtifacts(artifacts, contractName, workDir);

    // Step 2: Generate contract.config.ts
    console.log(`[contract] Step 2: Generating contract.config.ts...`);
    const configPath = join(workDir, 'contract.config.ts');
    const configResult = await generateContractConfig({
      contractName,
      compiledDir,
      outputPath: configPath,
      initialPrivateState,
    });
    console.log(
      `[contract] Config generated with ${configResult.witnessNames.length} witnesses`
    );

    // Step 3: Get wallet coin public key
    console.log(`[contract] Step 3: Getting coin public key...`);
    const seed = getWalletSeed(resolvedNetwork) ?? GENESIS_WALLET_SEED;
    const coinPublic = await getCoinPublicKey(seed, resolvedNetwork);
    console.log(`[contract] Coin public key: ${coinPublic.slice(0, 16)}...`);

    // Step 4: Generate deploy intent
    console.log(`[contract] Step 4: Generating deploy intent...`);
    const constructorArgsStrings = constructorArgs.map((arg) =>
      typeof arg === 'string' ? arg : JSON.stringify(arg)
    );
    const intentResult = await generateDeployIntent({
      configPath,
      coinPublic,
      outputDir: workDir,
      constructorArgs: constructorArgsStrings,
      network: resolvedNetwork === 'local' ? 'undeployed' : resolvedNetwork,
    });

    if (!intentResult.success) {
      return {
        success: false,
        network: resolvedNetwork,
        contractAddress: '',
        txId: '',
        message: `Failed to generate deploy intent: ${intentResult.error}`,
        workDir,
        errors: intentResult.error,
      };
    }

    // Step 5: Send intent to create transaction
    console.log(`[contract] Step 5: Sending intent...`);
    const sendResult = await sendIntent({
      intentFile: intentResult.intentFile,
      compiledContractDir: compiledDir,
      fundingSeed: seed,
      nodeRpcUrl,
      proofServerUrl,
    });

    if (!sendResult.success) {
      return {
        success: false,
        network: resolvedNetwork,
        contractAddress: '',
        txId: '',
        message: `Failed to create transaction: ${sendResult.error}`,
        workDir,
        errors: sendResult.error,
      };
    }

    // Step 6: Submit transaction to chain
    console.log(`[contract] Step 6: Submitting transaction...`);
    const submitResult = await submitTransaction(sendResult.txFile, nodeRpcUrl);

    if (!submitResult.success) {
      return {
        success: false,
        network: resolvedNetwork,
        contractAddress: '',
        txId: '',
        message: `Failed to submit transaction: ${submitResult.error}`,
        workDir,
        errors: submitResult.error,
      };
    }

    // Step 7: Extract contract address
    console.log(`[contract] Step 7: Extracting contract address...`);
    const addressResult = await extractContractAddress(sendResult.txFile);

    if (!addressResult.success) {
      return {
        success: false,
        network: resolvedNetwork,
        contractAddress: '',
        txId: '',
        message: `Failed to extract contract address: ${addressResult.error}`,
        workDir,
        errors: addressResult.error,
      };
    }

    const contractAddress = addressResult.address;

    // Step 8: Cache deployed contract info
    console.log(`[contract] Step 8: Caching contract info...`);
    contractCache.set(contractAddress, {
      address: contractAddress,
      contractName,
      compiledDir,
      configPath,
      privateStateFile: intentResult.privateStateFile,
      network: resolvedNetwork,
      deployedAt: new Date(),
      txId: '', // Transaction file doesn't expose txId directly
    });

    // Copy private state to persistent storage
    const persistedStateFile = await getPrivateStateFile(contractAddress);
    await copyFile(intentResult.privateStateFile, persistedStateFile);

    console.log(`[contract] Deployment successful: ${contractAddress}`);

    return {
      success: true,
      network: resolvedNetwork,
      contractAddress,
      txId: '', // Would need to parse from transaction
      message:
        `Contract deployed successfully on ${resolvedNetwork}.\n` +
        `Address: ${contractAddress}\n` +
        `Work directory: ${workDir}`,
      workDir,
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error';
    console.error(`[contract] Deployment failed:`, errorMessage);

    return {
      success: false,
      network: resolvedNetwork,
      contractAddress: '',
      txId: '',
      message: `Deployment failed: ${errorMessage}`,
      workDir,
      errors: errorMessage,
    };
  }
}

// -----------------------------------------------------------------------------
// Contract Call
// -----------------------------------------------------------------------------

/**
 * Call a circuit on a deployed contract.
 *
 * This uses the generate-intent circuit + send-intent flow:
 * 1. Fetch on-chain state
 * 2. Load private state from cache
 * 3. Generate circuit intent
 * 4. Send intent
 * 5. Update cached private state
 */
export async function callContractCircuit(
  params: CallParams,
  config: MidnightMCPConfig
): Promise<CallResult> {
  const { contractAddress, circuitName, args = [], network } = params;

  const resolvedNetwork = resolveNetwork(config, network);
  const nodeRpcUrl = getNodeRpcUrlConfig(config, resolvedNetwork);
  const proofServerUrl = getProofServerUrl(config, resolvedNetwork);

  // Get cached contract info
  const cached = getCachedContract(contractAddress);
  if (!cached) {
    return {
      success: false,
      network: resolvedNetwork,
      contractAddress,
      txId: '',
      message: `Contract ${contractAddress} not found in cache. Deploy it first or provide artifacts.`,
      errors: 'Contract not cached',
    };
  }

  // Create work directory for this call
  const workDir = join(CONTRACTS_DIR, `call-${randomUUID()}`);
  await mkdir(workDir, { recursive: true });

  console.log(`[contract] Call work directory: ${workDir}`);

  try {
    // Step 0: Copy managed/ folder from cached deployment to work directory
    // This is needed because generateCircuitIntent copies the entire outputDir to toolkit-js
    console.log(`[contract] Step 0: Copying compiled artifacts to work dir...`);
    const { execFile } = await import('child_process');
    const { promisify } = await import('util');
    const execFileAsync = promisify(execFile);

    // cached.compiledDir is like /tmp/midnight-contracts/deploy-xxx/managed/counter
    // We need to copy the managed/ folder (parent of cached.compiledDir)
    const managedDir = join(cached.compiledDir, '..');
    await execFileAsync('cp', ['-r', managedDir, workDir + '/'], {
      encoding: 'utf-8',
    });

    // Copy config file to work directory
    const workConfigPath = join(workDir, 'contract.config.ts');
    await execFileAsync('cp', [cached.configPath, workConfigPath], {
      encoding: 'utf-8',
    });

    // Step 1: Fetch on-chain state
    console.log(`[contract] Step 1: Fetching on-chain state...`);
    const onchainStateFile = join(workDir, 'onchain_state.bin');
    const stateResult = await fetchContractState(
      contractAddress,
      nodeRpcUrl,
      onchainStateFile
    );

    if (!stateResult.success) {
      return {
        success: false,
        network: resolvedNetwork,
        contractAddress,
        txId: '',
        message: `Failed to fetch on-chain state: ${stateResult.error}`,
        errors: stateResult.error,
      };
    }

    // Step 2: Load private state
    console.log(`[contract] Step 2: Loading private state...`);
    const privateStateFile = await getPrivateStateFile(contractAddress);

    // Step 3: Get wallet coin public key
    console.log(`[contract] Step 3: Getting coin public key...`);
    const seed = getWalletSeed(resolvedNetwork) ?? GENESIS_WALLET_SEED;
    const coinPublic = await getCoinPublicKey(seed, resolvedNetwork);

    // Step 4: Generate circuit intent
    console.log(
      `[contract] Step 4: Generating circuit intent for ${circuitName}...`
    );
    const argsStrings = args.map((arg) =>
      typeof arg === 'string' ? arg : JSON.stringify(arg)
    );
    const intentResult = await generateCircuitIntent({
      configPath: workConfigPath, // Use the copied config in work directory
      coinPublic,
      contractAddress,
      circuitName,
      onchainStateFile,
      privateStateFile,
      outputDir: workDir,
      args: argsStrings,
      network: resolvedNetwork === 'local' ? 'undeployed' : resolvedNetwork,
      nodeRpcUrl,
    });

    if (!intentResult.success) {
      return {
        success: false,
        network: resolvedNetwork,
        contractAddress,
        txId: '',
        message: `Failed to generate circuit intent: ${intentResult.error}`,
        errors: intentResult.error,
      };
    }

    // Step 5: Send intent
    console.log(`[contract] Step 5: Sending circuit intent...`);
    // Use the compiled dir in the work directory (we copied managed/ there)
    const workCompiledDir = join(workDir, 'managed', cached.contractName);
    const sendResult = await sendIntent({
      intentFile: intentResult.intentFile,
      compiledContractDir: workCompiledDir,
      fundingSeed: seed,
      nodeRpcUrl,
      proofServerUrl,
    });

    if (!sendResult.success) {
      return {
        success: false,
        network: resolvedNetwork,
        contractAddress,
        txId: '',
        message: `Failed to send circuit intent: ${sendResult.error}`,
        errors: sendResult.error,
      };
    }

    // Step 6: Update cached private state
    console.log(`[contract] Step 6: Updating private state...`);
    const persistedStateFile = await getPrivateStateFile(contractAddress);
    await copyFile(intentResult.newPrivateStateFile, persistedStateFile);

    console.log(`[contract] Circuit call successful: ${circuitName}`);

    return {
      success: true,
      network: resolvedNetwork,
      contractAddress,
      txId: '', // Would need to parse from send output
      message: `Circuit ${circuitName} called successfully on contract ${contractAddress}.`,
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error';
    console.error(`[contract] Circuit call failed:`, errorMessage);

    return {
      success: false,
      network: resolvedNetwork,
      contractAddress,
      txId: '',
      message: `Circuit call failed: ${errorMessage}`,
      errors: errorMessage,
    };
  }
}

// -----------------------------------------------------------------------------
// Legacy Exports (for backwards compatibility)
// -----------------------------------------------------------------------------

/**
 * @deprecated Use deployContractFromArtifacts instead
 */
export async function deployContract(
  _compiledContractDir: string,
  _intentFile: string,
  _config: MidnightMCPConfig,
  network?: string,
  _fundingSeed?: string
): Promise<DeployResult> {
  // This is the old interface that required pre-generated intent files
  // New code should use deployContractFromArtifacts
  return {
    success: false,
    network: network || 'unknown',
    contractAddress: '',
    txId: '',
    message:
      'This method is deprecated. Use deployContractFromArtifacts with artifacts from compact_compile.',
    errors: 'Deprecated method',
  };
}

/**
 * @deprecated Use callContractCircuit instead
 */
export async function callContract(
  _compiledContractDir: string,
  _intentFile: string,
  _config: MidnightMCPConfig,
  network?: string,
  _fundingSeed?: string
): Promise<CallResult> {
  // This is the old interface that required pre-generated intent files
  // New code should use callContractCircuit
  return {
    success: false,
    network: network || 'unknown',
    contractAddress: '',
    txId: '',
    message:
      'This method is deprecated. Use callContractCircuit with contract address and circuit name.',
    errors: 'Deprecated method',
  };
}
