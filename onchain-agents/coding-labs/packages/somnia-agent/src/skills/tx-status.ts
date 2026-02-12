import type { Message } from '@a2a-js/sdk';
import type { WalletContext, TransactionStatus } from '@coding-labs/shared';
import { createPublicClient, http, type Hex } from 'viem';
import { extractTextFromMessage, type SkillEvent } from './index.js';
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
 * Extract transaction hash from user message
 */
function extractTxHash(text: string): Hex | null {
  // Match 0x followed by 64 hex characters
  const match = text.match(/0x[a-fA-F0-9]{64}/);
  return match ? (match[0] as Hex) : null;
}

/**
 * Detect network preference from message
 */
function detectNetwork(
  text: string,
  walletChainId?: number
): 'mainnet' | 'testnet' {
  const lower = text.toLowerCase();

  if (lower.includes('mainnet') || lower.includes('main net')) {
    return 'mainnet';
  }
  if (
    lower.includes('testnet') ||
    lower.includes('test net') ||
    lower.includes('shannon')
  ) {
    return 'testnet';
  }

  // Use wallet chain ID if connected
  if (walletChainId === 5031) {
    return 'mainnet';
  }

  // Default to testnet
  return 'testnet';
}

/**
 * Format wei to readable amount
 */
function formatWei(wei: bigint, decimals: number = 18): string {
  const value = Number(wei) / Math.pow(10, decimals);
  if (value < 0.000001) {
    return wei.toString() + ' wei';
  }
  return value.toFixed(6);
}

/**
 * Transaction status skill - check the status of a transaction on Somnia
 */
export async function* checkTxStatus(
  userMessage: Message,
  walletContext?: WalletContext
): AsyncGenerator<SkillEvent, void, unknown> {
  const userText = extractTextFromMessage(userMessage);

  if (!userText.trim()) {
    yield {
      type: 'error',
      message: 'No input provided. Please provide a transaction hash to check.',
    };
    return;
  }

  // Extract transaction hash
  const txHash = extractTxHash(userText);
  if (!txHash) {
    yield {
      type: 'error',
      message:
        'No valid transaction hash found. Please provide a transaction hash (0x followed by 64 hex characters).',
    };
    return;
  }

  // Detect network
  const network = detectNetwork(userText, walletContext?.chainId);
  const isMainnet = network === 'mainnet';
  const chain = isMainnet ? somniaMainnet : somniaTestnet;
  const networkConfig = isMainnet ? SOMNIA_MAINNET : SOMNIA_TESTNET;

  yield {
    type: 'status',
    message: `Checking transaction ${txHash.slice(0, 10)}...${txHash.slice(-8)} on ${chain.name}...`,
  };

  try {
    // Create viem client
    const client = createPublicClient({
      chain,
      transport: http(networkConfig.rpcUrl),
    });

    // Fetch transaction and receipt
    yield { type: 'status', message: 'Fetching transaction details...' };

    const [tx, receipt] = await Promise.all([
      client.getTransaction({ hash: txHash }).catch(() => null),
      client.getTransactionReceipt({ hash: txHash }).catch(() => null),
    ]);

    if (!tx) {
      // Transaction not found - might be pending or doesn't exist
      yield {
        type: 'artifact',
        name: 'tx-status.json',
        content: JSON.stringify(
          {
            hash: txHash,
            status: 'not_found',
            network: chain.name,
            message:
              'Transaction not found. It may be pending, not yet mined, or may not exist on this network.',
            explorerUrl: `${networkConfig.explorerUrl}/tx/${txHash}`,
          },
          null,
          2
        ),
        mimeType: 'application/json',
      };

      yield {
        type: 'result',
        data: {
          hash: txHash,
          status: 'not_found',
          network: chain.name,
        },
      };
      return;
    }

    // Build status response
    let status: TransactionStatus['status'];
    if (!receipt) {
      status = 'pending';
    } else if (receipt.status === 'success') {
      status = 'success';
    } else {
      status = 'failed';
    }

    const txStatus: TransactionStatus = {
      hash: txHash,
      status,
      from: tx.from,
      to: tx.to ?? undefined,
      blockNumber: receipt?.blockNumber
        ? Number(receipt.blockNumber)
        : undefined,
      gasUsed: receipt?.gasUsed,
      logs: receipt?.logs?.map((log) => ({
        address: log.address,
        topics: log.topics as string[],
        data: log.data,
      })),
    };

    // Calculate gas cost if available
    let gasCost: string | undefined;
    if (receipt?.gasUsed && receipt?.effectiveGasPrice) {
      const cost = receipt.gasUsed * receipt.effectiveGasPrice;
      gasCost = `${formatWei(cost)} ${chain.nativeCurrency.symbol}`;
    }

    // Determine if this is a contract deployment
    const isContractCreation = !tx.to;
    let contractAddress: string | undefined;
    if (isContractCreation && receipt?.contractAddress) {
      contractAddress = receipt.contractAddress;
    }

    // Build detailed output
    const details = {
      hash: txHash,
      status,
      network: chain.name,
      from: tx.from,
      to: tx.to ?? 'Contract Creation',
      value: `${formatWei(tx.value)} ${chain.nativeCurrency.symbol}`,
      blockNumber: receipt?.blockNumber
        ? Number(receipt.blockNumber)
        : 'Pending',
      gasUsed: receipt?.gasUsed?.toString() ?? 'Pending',
      gasCost: gasCost ?? 'Pending',
      nonce: tx.nonce,
      ...(contractAddress && { contractAddress }),
      logsCount: receipt?.logs?.length ?? 0,
      explorerUrl: `${networkConfig.explorerUrl}/tx/${txHash}`,
    };

    yield {
      type: 'artifact',
      name: 'tx-status.json',
      content: JSON.stringify(details, null, 2),
      mimeType: 'application/json',
    };

    // Emit logs separately if there are any
    if (receipt?.logs && receipt.logs.length > 0) {
      yield {
        type: 'artifact',
        name: 'tx-logs.json',
        content: JSON.stringify(
          receipt.logs.map((log, i) => ({
            index: i,
            address: log.address,
            topics: log.topics,
            data: log.data,
          })),
          null,
          2
        ),
        mimeType: 'application/json',
      };
    }

    // Generate human-readable summary
    let summary = `Transaction ${status.toUpperCase()}\n\n`;
    summary += `Hash: ${txHash}\n`;
    summary += `Network: ${chain.name}\n`;
    summary += `From: ${tx.from}\n`;
    summary += `To: ${tx.to ?? 'Contract Creation'}\n`;

    if (contractAddress) {
      summary += `Contract Deployed: ${contractAddress}\n`;
    }

    summary += `Value: ${formatWei(tx.value)} ${chain.nativeCurrency.symbol}\n`;

    if (receipt) {
      summary += `Block: ${receipt.blockNumber}\n`;
      summary += `Gas Used: ${receipt.gasUsed}\n`;
      if (gasCost) {
        summary += `Gas Cost: ${gasCost}\n`;
      }
      summary += `Logs: ${receipt.logs.length}\n`;
    }

    summary += `\nExplorer: ${networkConfig.explorerUrl}/tx/${txHash}`;

    yield {
      type: 'artifact',
      name: 'summary.txt',
      content: summary,
      mimeType: 'text/plain',
    };

    yield {
      type: 'result',
      data: txStatus,
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error occurred';
    yield {
      type: 'error',
      message: `Failed to check transaction status: ${errorMessage}`,
    };
  }
}
