/**
 * Forge command wrappers.
 *
 * Forge is Foundry's build/test/deploy tool. We use it for:
 * - Compiling Solidity contracts
 * - Deploying contracts (with Anvil accounts or returning unsigned tx)
 * - Running tests (future)
 */

import { execFile } from 'child_process';
import { promisify } from 'util';
import { mkdir, writeFile, readFile, rm } from 'fs/promises';
import { join } from 'path';
import { randomUUID } from 'crypto';
import type { EvmMcpConfig } from '../config.js';

const execFileAsync = promisify(execFile);

// -----------------------------------------------------------------------------
// Types
// -----------------------------------------------------------------------------

export interface CompileResult {
  success: boolean;
  contractName: string;
  abi: unknown[];
  bytecode: string;
  deployedBytecode: string;
  solcVersion: string;
  errors?: string;
}

export interface DeployResult {
  success: boolean;
  contractAddress?: string;
  txHash?: string;
  unsignedTx?: {
    to: null;
    data: string;
    chainId: number;
    gasLimit: string;
    value: string;
  };
  error?: string;
}

// -----------------------------------------------------------------------------
// Forge Compile
// -----------------------------------------------------------------------------

/**
 * Compile Solidity source code using Forge.
 *
 * Creates a temporary Foundry project, compiles the contract,
 * and returns the ABI and bytecode.
 */
export async function forgeCompile(
  source: string,
  config: EvmMcpConfig,
  options?: {
    filename?: string;
    solcVersion?: string;
  }
): Promise<CompileResult> {
  const filename = options?.filename || 'Contract.sol';
  const solcVersion = options?.solcVersion || config.defaultSolcVersion;
  const projectId = randomUUID();
  const projectDir = join(config.tempDir, projectId);

  try {
    // Create minimal Foundry project structure
    await mkdir(projectDir, { recursive: true });
    await mkdir(join(projectDir, 'src'), { recursive: true });

    // Write foundry.toml
    const foundryConfig = `
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc_version = "${solcVersion}"
`;
    await writeFile(join(projectDir, 'foundry.toml'), foundryConfig);

    // Write the Solidity source
    const sourcePath = join(projectDir, 'src', filename);
    await writeFile(sourcePath, source);

    // Run forge build
    console.log(`[evm-mcp] Compiling ${filename} with solc ${solcVersion}`);
    const { stderr } = await execFileAsync('forge', ['build', '--force'], {
      cwd: projectDir,
      timeout: 60000, // 60 second timeout
    });

    if (stderr && stderr.includes('Error')) {
      return {
        success: false,
        contractName: '',
        abi: [],
        bytecode: '',
        deployedBytecode: '',
        solcVersion,
        errors: stderr,
      };
    }

    // Extract contract name from filename (e.g., Token.sol -> Token)
    const contractName = filename.replace('.sol', '');

    // Read compiled artifacts
    const artifactPath = join(
      projectDir,
      'out',
      filename,
      `${contractName}.json`
    );
    const artifactContent = await readFile(artifactPath, 'utf-8');
    const artifact = JSON.parse(artifactContent);

    // Cleanup
    await rm(projectDir, { recursive: true, force: true });

    return {
      success: true,
      contractName,
      abi: artifact.abi,
      bytecode: artifact.bytecode.object,
      deployedBytecode: artifact.deployedBytecode.object,
      solcVersion,
    };
  } catch (error) {
    // Cleanup on error
    try {
      await rm(projectDir, { recursive: true, force: true });
    } catch {
      // Ignore cleanup errors
    }

    const errorMessage = error instanceof Error ? error.message : String(error);
    return {
      success: false,
      contractName: '',
      abi: [],
      bytecode: '',
      deployedBytecode: '',
      solcVersion,
      errors: errorMessage,
    };
  }
}

/**
 * Deploy a contract using Forge.
 *
 * If devMode is true and rpcUrl points to local Anvil, deploys with test account.
 * Otherwise, returns unsigned transaction for user to sign.
 */
export async function forgeDeploy(
  bytecode: string,
  _abi: unknown[],
  options: {
    rpcUrl: string;
    chainId: number;
    constructorArgs?: unknown[];
    devMode?: boolean;
    privateKey?: string;
  }
): Promise<DeployResult> {
  const { rpcUrl, chainId, devMode, privateKey } = options;
  // Note: constructorArgs would need to be ABI-encoded and appended to bytecode
  // Future enhancement: use cast abi-encode for constructor args

  // If not dev mode, return unsigned transaction
  if (!devMode) {
    return {
      success: true,
      unsignedTx: {
        to: null,
        data: bytecode.startsWith('0x') ? bytecode : `0x${bytecode}`,
        chainId,
        gasLimit: '3000000', // Default gas limit, user can adjust
        value: '0x0',
      },
    };
  }

  // Dev mode: deploy using forge create with private key
  if (!privateKey) {
    return {
      success: false,
      error: 'Private key required for dev mode deployment',
    };
  }

  try {
    // Use cast to deploy (simpler than forge create for raw bytecode)
    const args = [
      'send',
      '--rpc-url',
      rpcUrl,
      '--private-key',
      privateKey,
      '--create',
      bytecode.startsWith('0x') ? bytecode : `0x${bytecode}`,
    ];

    console.log(`[evm-mcp] Deploying contract via cast send --create`);
    const { stdout } = await execFileAsync('cast', args, {
      timeout: 120000, // 2 minute timeout for deployment
    });

    // Parse the output to get contract address and tx hash
    // cast send outputs: blockHash, blockNumber, contractAddress, etc.
    const lines = stdout.split('\n');
    let contractAddress = '';
    let txHash = '';

    for (const line of lines) {
      if (line.startsWith('contractAddress')) {
        contractAddress = line.split(/\s+/)[1];
      }
      if (line.startsWith('transactionHash')) {
        txHash = line.split(/\s+/)[1];
      }
    }

    if (!contractAddress) {
      return {
        success: false,
        error: `Deployment succeeded but could not parse contract address from output: ${stdout}`,
      };
    }

    return {
      success: true,
      contractAddress,
      txHash,
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    return {
      success: false,
      error: `Deployment failed: ${errorMessage}`,
    };
  }
}
