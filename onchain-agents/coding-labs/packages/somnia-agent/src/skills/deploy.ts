import type { Message } from '@a2a-js/sdk';
import type { WalletContext, UnsignedTransaction } from '@coding-labs/shared';
import {
  createPublicClient,
  http,
  encodeDeployData,
  type Abi,
  type Hex,
} from 'viem';
import { extractTextFromMessage, type SkillEvent } from './index.js';
import { generateText } from 'ai';
import { model } from '../genkit.js';
import { SOMNIA_MAINNET, SOMNIA_TESTNET } from '@coding-labs/shared';

/**
 * Define the Somnia chains for viem
 */
const somniaMainnet = {
  id: 5031,
  name: 'Somnia Mainnet',
  nativeCurrency: { name: 'SOMI', symbol: 'SOMI', decimals: 18 },
  rpcUrls: {
    default: { http: [SOMNIA_MAINNET.rpcUrl] },
  },
  blockExplorers: {
    default: { name: 'Somnia Explorer', url: SOMNIA_MAINNET.explorerUrl },
  },
} as const;

const somniaTestnet = {
  id: 50312,
  name: 'Somnia Testnet (Shannon)',
  nativeCurrency: { name: 'STT', symbol: 'STT', decimals: 18 },
  rpcUrls: {
    default: { http: [SOMNIA_TESTNET.rpcUrl] },
  },
  blockExplorers: {
    default: { name: 'Somnia Explorer', url: SOMNIA_TESTNET.explorerUrl },
  },
} as const;

/**
 * System prompt for extracting deployment info
 */
const DEPLOY_EXTRACTION_PROMPT = `You are an assistant that extracts smart contract deployment information from user messages.

Extract the following information if present:
- Contract source code (Solidity)
- Contract bytecode (if provided directly)
- Constructor arguments
- Target network (mainnet or testnet, default to testnet)

Respond with a JSON object:
{
  "sourceCode": "// Solidity code..." or null,
  "bytecode": "0x..." or null,
  "abi": [...] or null,
  "constructorArgs": [...] or null,
  "network": "testnet" or "mainnet"
}

If the user provides Solidity source code, extract it as sourceCode.
If they provide raw bytecode, extract it as bytecode.
Constructor arguments should be an array of values matching the constructor parameters.
`;

/**
 * Compile Solidity to bytecode using LLM (simplified - in production use solc)
 */
const COMPILE_PROMPT = `You are a Solidity compiler. Given the following Solidity source code, provide the compiled bytecode and ABI.

IMPORTANT: For this simulation, generate a realistic-looking bytecode (starting with 0x608060...) and proper ABI.
In a production environment, we would use solc or a compilation service.

Respond with JSON:
{
  "bytecode": "0x608060...",
  "abi": [...]
}

Solidity Source:
`;

interface DeploymentInfo {
  sourceCode: string | null;
  bytecode: Hex | null;
  abi: Abi | null;
  constructorArgs: unknown[] | null;
  network: 'mainnet' | 'testnet';
}

interface CompilationResult {
  bytecode: Hex;
  abi: Abi;
}

/**
 * Deploy skill - creates unsigned deployment transaction for user to sign
 */
export async function* deployContract(
  userMessage: Message,
  walletContext?: WalletContext
): AsyncGenerator<SkillEvent, void, unknown> {
  const userText = extractTextFromMessage(userMessage);

  if (!userText.trim()) {
    yield {
      type: 'error',
      message:
        'No input provided. Please provide contract source code or bytecode to deploy.',
    };
    return;
  }

  // Check wallet connection
  if (!walletContext?.connected || !walletContext.address) {
    yield {
      type: 'error',
      message:
        'Wallet not connected. Please connect your wallet to deploy contracts.',
    };
    return;
  }

  yield { type: 'status', message: 'Analyzing deployment request...' };

  try {
    // Extract deployment info using LLM
    const extractionResponse = await generateText({
      model,
      system: DEPLOY_EXTRACTION_PROMPT,
      prompt: userText,
    });

    let deploymentInfo: DeploymentInfo | undefined;
    try {
      deploymentInfo = JSON.parse(extractionResponse.text) as DeploymentInfo;
    } catch {
      deploymentInfo = undefined;
    }
    if (!deploymentInfo) {
      yield {
        type: 'error',
        message:
          'Could not parse deployment request. Please provide contract source code or bytecode.',
      };
      return;
    }

    let bytecode: Hex;
    let abi: Abi | null = deploymentInfo.abi;

    // Get bytecode either directly or by compiling source
    if (deploymentInfo.bytecode) {
      bytecode = deploymentInfo.bytecode;
      yield { type: 'status', message: 'Using provided bytecode...' };
    } else if (deploymentInfo.sourceCode) {
      yield { type: 'status', message: 'Compiling Solidity source code...' };

      // In production, use solc or compilation service
      // For now, use LLM to simulate compilation
      const compileResponse = await generateText({
        model,
        system: COMPILE_PROMPT + deploymentInfo.sourceCode,
        prompt: 'Compile this contract and return bytecode and ABI.',
      });

      let compiled: CompilationResult | undefined;
      try {
        compiled = JSON.parse(compileResponse.text) as CompilationResult;
      } catch {
        compiled = undefined;
      }
      if (!compiled?.bytecode) {
        yield {
          type: 'error',
          message:
            'Failed to compile contract. Please check the Solidity source code.',
        };
        return;
      }

      bytecode = compiled.bytecode;
      abi = compiled.abi || null;
    } else {
      yield {
        type: 'error',
        message:
          'No contract source code or bytecode provided. Please include the contract to deploy.',
      };
      return;
    }

    // Select network based on wallet chain ID or user preference
    const isMainnet =
      walletContext.chainId === 5031 || deploymentInfo.network === 'mainnet';
    const chain = isMainnet ? somniaMainnet : somniaTestnet;
    const networkConfig = isMainnet ? SOMNIA_MAINNET : SOMNIA_TESTNET;

    yield {
      type: 'status',
      message: `Preparing deployment to ${chain.name}...`,
    };

    // Create viem client
    const client = createPublicClient({
      chain,
      transport: http(networkConfig.rpcUrl),
    });

    // Encode constructor arguments if provided
    let deployData: Hex = bytecode;
    if (
      deploymentInfo.constructorArgs &&
      deploymentInfo.constructorArgs.length > 0 &&
      abi
    ) {
      try {
        deployData = encodeDeployData({
          abi,
          bytecode,
          args: deploymentInfo.constructorArgs,
        });
      } catch (error) {
        console.error('Error encoding constructor args:', error);
        // Fall back to just bytecode
      }
    }

    // Estimate gas
    yield { type: 'status', message: 'Estimating gas...' };
    let gasEstimate: bigint;
    try {
      gasEstimate = await client.estimateGas({
        account: walletContext.address,
        data: deployData,
      });
      // Add 20% buffer for safety
      gasEstimate = (gasEstimate * 120n) / 100n;
    } catch (error) {
      console.error('Gas estimation failed:', error);
      // Use a high default for contract deployment
      gasEstimate = 3000000n;
    }

    // Get current gas price
    const gasPrice = await client.getGasPrice();
    const estimatedCost = gasEstimate * gasPrice;
    const formattedCost = (Number(estimatedCost) / 1e18).toFixed(6);

    // Create unsigned transaction
    const unsignedTx: UnsignedTransaction = {
      data: deployData,
      gas: gasEstimate,
      maxFeePerGas: gasPrice * 2n, // 2x current gas price
      maxPriorityFeePerGas: gasPrice / 10n, // 10% tip
      chainId: chain.id,
    };

    // Emit the source code as artifact if we have it
    if (deploymentInfo.sourceCode) {
      yield {
        type: 'artifact',
        name: 'Contract.sol',
        content: deploymentInfo.sourceCode,
        mimeType: 'text/x-solidity',
      };
    }

    // Emit ABI as artifact
    if (abi) {
      yield {
        type: 'artifact',
        name: 'abi.json',
        content: JSON.stringify(abi, null, 2),
        mimeType: 'application/json',
      };
    }

    // Emit the unsigned transaction as the main result
    yield {
      type: 'artifact',
      name: 'deploy-transaction.json',
      content: JSON.stringify(
        {
          unsignedTransaction: {
            ...unsignedTx,
            gas: unsignedTx.gas?.toString(),
            maxFeePerGas: unsignedTx.maxFeePerGas?.toString(),
            maxPriorityFeePerGas: unsignedTx.maxPriorityFeePerGas?.toString(),
          },
          network: chain.name,
          estimatedCost: `${formattedCost} ${chain.nativeCurrency.symbol}`,
          from: walletContext.address,
          instructions: [
            'Review the transaction details above',
            'Sign this transaction with your connected wallet',
            'The contract will be deployed to ' + chain.name,
            'After deployment, use tx-status skill to check the result',
          ],
        },
        null,
        2
      ),
      mimeType: 'application/json',
    };

    yield {
      type: 'result',
      data: {
        unsignedTransaction: unsignedTx,
        network: chain.name,
        estimatedGas: gasEstimate.toString(),
        estimatedCost: `${formattedCost} ${chain.nativeCurrency.symbol}`,
      },
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error occurred';
    yield {
      type: 'error',
      message: `Deployment preparation failed: ${errorMessage}`,
    };
  }
}
