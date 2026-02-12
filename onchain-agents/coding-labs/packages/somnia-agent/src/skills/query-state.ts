import type { Message } from '@a2a-js/sdk';
import type { WalletContext } from '@coding-labs/shared';
import {
  createPublicClient,
  http,
  type Address,
  parseAbi,
  formatUnits,
  getContract,
} from 'viem';
import { extractTextFromMessage, type SkillEvent } from './index.js';
import { ai } from '../genkit.js';
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
 * Known contract addresses on Somnia mainnet
 */
const KNOWN_CONTRACTS: Record<
  string,
  { address: Address; abi: readonly string[] }
> = {
  USDC: {
    address: '0x28BEc7E30E6faee657a03e19Bf1128AaD7632A00',
    abi: [
      'function balanceOf(address) view returns (uint256)',
      'function totalSupply() view returns (uint256)',
      'function decimals() view returns (uint8)',
      'function symbol() view returns (string)',
      'function name() view returns (string)',
    ],
  },
  WSOMI: {
    address: '0x046EDe9564A72571df6F5e44d0405360c0f4dCab',
    abi: [
      'function balanceOf(address) view returns (uint256)',
      'function totalSupply() view returns (uint256)',
      'function decimals() view returns (uint8)',
      'function symbol() view returns (string)',
      'function name() view returns (string)',
    ],
  },
  WETH: {
    address: '0x936Ab8C674bcb567CD5dEB85D8A216494704E9D8',
    abi: [
      'function balanceOf(address) view returns (uint256)',
      'function totalSupply() view returns (uint256)',
      'function decimals() view returns (uint8)',
      'function symbol() view returns (string)',
      'function name() view returns (string)',
    ],
  },
  USDT: {
    address: '0x67B302E35Aef5EEE8c32D934F5856869EF428330',
    abi: [
      'function balanceOf(address) view returns (uint256)',
      'function totalSupply() view returns (uint256)',
      'function decimals() view returns (uint8)',
      'function symbol() view returns (string)',
      'function name() view returns (string)',
    ],
  },
};

/**
 * Common ERC-20 ABI
 */
const ERC20_ABI = [
  'function balanceOf(address) view returns (uint256)',
  'function totalSupply() view returns (uint256)',
  'function decimals() view returns (uint8)',
  'function symbol() view returns (string)',
  'function name() view returns (string)',
  'function allowance(address owner, address spender) view returns (uint256)',
] as const;

/**
 * Common ERC-721 ABI (for future use with NFT queries)
 */
const _ERC721_ABI = [
  'function balanceOf(address) view returns (uint256)',
  'function ownerOf(uint256) view returns (address)',
  'function name() view returns (string)',
  'function symbol() view returns (string)',
  'function tokenURI(uint256) view returns (string)',
  'function totalSupply() view returns (uint256)',
] as const;
// Exported for future use
export { _ERC721_ABI as ERC721_ABI };

/**
 * System prompt for extracting query info
 */
const QUERY_EXTRACTION_PROMPT = `You are an assistant that extracts smart contract query information from user messages.

Known contracts on Somnia mainnet:
- USDC: 0x28BEc7E30E6faee657a03e19Bf1128AaD7632A00
- WSOMI: 0x046EDe9564A72571df6F5e44d0405360c0f4dCab
- WETH: 0x936Ab8C674bcb567CD5dEB85D8A216494704E9D8
- USDT: 0x67B302E35Aef5EEE8c32D934F5856869EF428330

Extract:
1. Contract address (or known contract name)
2. Function to call (balanceOf, totalSupply, ownerOf, etc.)
3. Function arguments
4. Network preference (mainnet/testnet)
5. Whether to get native balance (STT/SOMI) instead of contract state

Respond with JSON:
{
  "queryType": "native_balance" | "contract_call",
  "contractAddress": "0x..." or null,
  "contractName": "USDC" or null,
  "functionName": "balanceOf" or null,
  "args": [...] or null,
  "targetAddress": "0x..." or null,
  "network": "mainnet" | "testnet"
}

Examples:
- "Get my balance" -> queryType: "native_balance", targetAddress from context
- "What is the USDC balance of 0x123..." -> queryType: "contract_call", contractName: "USDC", functionName: "balanceOf", args: ["0x123..."]
- "Total supply of contract 0xabc..." -> queryType: "contract_call", contractAddress: "0xabc...", functionName: "totalSupply"
`;

interface QueryInfo {
  queryType: 'native_balance' | 'contract_call';
  contractAddress: Address | null;
  contractName: string | null;
  functionName: string | null;
  args: unknown[] | null;
  targetAddress: Address | null;
  network: 'mainnet' | 'testnet';
}

/**
 * Extract addresses from text
 */
function extractAddresses(text: string): Address[] {
  const matches = text.match(/0x[a-fA-F0-9]{40}/g);
  return (matches || []) as Address[];
}

/**
 * Query state skill - read on-chain state from Somnia contracts
 */
export async function* queryState(
  userMessage: Message,
  walletContext?: WalletContext
): AsyncGenerator<SkillEvent, void, unknown> {
  const userText = extractTextFromMessage(userMessage);

  if (!userText.trim()) {
    yield {
      type: 'error',
      message:
        'No input provided. Please describe what on-chain state you want to query.',
    };
    return;
  }

  yield { type: 'status', message: 'Analyzing query request...' };

  try {
    // Extract query info using LLM
    const extractionResponse = await ai.generate({
      system: QUERY_EXTRACTION_PROMPT,
      prompt: `User wallet: ${walletContext?.address ?? 'not connected'}\n\nUser request: ${userText}`,
      output: { format: 'json' },
    });

    const queryInfo = extractionResponse.output as QueryInfo | undefined;
    if (!queryInfo) {
      yield {
        type: 'error',
        message:
          'Could not parse query request. Please specify the contract and function to call.',
      };
      return;
    }

    // Determine network
    const isMainnet =
      walletContext?.chainId === 5031 || queryInfo.network === 'mainnet';
    const chain = isMainnet ? somniaMainnet : somniaTestnet;
    const networkConfig = isMainnet ? SOMNIA_MAINNET : SOMNIA_TESTNET;

    yield {
      type: 'status',
      message: `Querying ${chain.name}...`,
    };

    // Create viem client
    const client = createPublicClient({
      chain,
      transport: http(networkConfig.rpcUrl),
    });

    // Handle native balance query
    if (queryInfo.queryType === 'native_balance') {
      const targetAddress = queryInfo.targetAddress || walletContext?.address;
      if (!targetAddress) {
        yield {
          type: 'error',
          message:
            'No address specified and wallet not connected. Please provide an address.',
        };
        return;
      }

      yield {
        type: 'status',
        message: `Getting native balance for ${targetAddress}...`,
      };

      const balance = await client.getBalance({ address: targetAddress });
      const formatted = formatUnits(balance, 18);

      const result = {
        address: targetAddress,
        balance: formatted,
        balanceWei: balance.toString(),
        symbol: chain.nativeCurrency.symbol,
        network: chain.name,
      };

      yield {
        type: 'artifact',
        name: 'balance.json',
        content: JSON.stringify(result, null, 2),
        mimeType: 'application/json',
      };

      yield {
        type: 'artifact',
        name: 'summary.txt',
        content: `Address: ${targetAddress}\nBalance: ${formatted} ${chain.nativeCurrency.symbol}\nNetwork: ${chain.name}`,
        mimeType: 'text/plain',
      };

      yield { type: 'result', data: result };
      return;
    }

    // Handle contract call
    let contractAddress = queryInfo.contractAddress;
    let abi: readonly string[] = ERC20_ABI;

    // Resolve known contract name
    if (queryInfo.contractName && !contractAddress) {
      const known = KNOWN_CONTRACTS[queryInfo.contractName.toUpperCase()];
      if (known) {
        contractAddress = known.address;
        abi = known.abi;
      }
    }

    if (!contractAddress) {
      // Try to extract from user text
      const addresses = extractAddresses(userText);
      if (addresses.length > 0) {
        contractAddress = addresses[0];
      } else {
        yield {
          type: 'error',
          message:
            'No contract address provided. Please specify the contract address.',
        };
        return;
      }
    }

    const functionName = queryInfo.functionName || 'balanceOf';
    let args = queryInfo.args || [];

    // If it's a balanceOf call without args, use the target address or wallet
    if (
      functionName === 'balanceOf' &&
      args.length === 0 &&
      (queryInfo.targetAddress || walletContext?.address)
    ) {
      args = [queryInfo.targetAddress || walletContext?.address];
    }

    yield {
      type: 'status',
      message: `Calling ${functionName} on ${contractAddress.slice(0, 10)}...`,
    };

    // Try to get contract info first
    let tokenInfo: { name?: string; symbol?: string; decimals?: number } = {};
    try {
      const contract = getContract({
        address: contractAddress,
        abi: parseAbi(ERC20_ABI),
        client,
      });

      const [name, symbol, decimals] = await Promise.all([
        contract.read.name().catch(() => undefined),
        contract.read.symbol().catch(() => undefined),
        contract.read.decimals().catch(() => undefined),
      ]);

      tokenInfo = { name, symbol, decimals };
    } catch {
      // Not an ERC-20, continue anyway
    }

    // Make the actual call
    try {
      const result = await client.readContract({
        address: contractAddress,
        abi: parseAbi(abi as readonly string[]),
        functionName: functionName as never,
        args: args as never,
      });

      // Format the result
      let formattedResult: unknown = result;
      let humanReadable = '';

      if (typeof result === 'bigint') {
        const decimals = tokenInfo.decimals || 18;
        const formatted = formatUnits(result, decimals);
        formattedResult = {
          raw: result.toString(),
          formatted,
          decimals,
        };
        humanReadable = `${formatted} ${tokenInfo.symbol || 'tokens'}`;
      } else if (typeof result === 'string' || typeof result === 'number') {
        formattedResult = result;
        humanReadable = String(result);
      } else {
        formattedResult = result;
        humanReadable = JSON.stringify(result, (_, v) =>
          typeof v === 'bigint' ? v.toString() : v
        );
      }

      const output = {
        contract: {
          address: contractAddress,
          name: tokenInfo.name,
          symbol: tokenInfo.symbol,
        },
        function: functionName,
        args: args,
        result: formattedResult,
        network: chain.name,
        explorerUrl: `${networkConfig.explorerUrl}/address/${contractAddress}`,
      };

      yield {
        type: 'artifact',
        name: 'query-result.json',
        content: JSON.stringify(
          output,
          (_, v) => (typeof v === 'bigint' ? v.toString() : v),
          2
        ),
        mimeType: 'application/json',
      };

      // Generate summary
      let summary = `Contract: ${tokenInfo.name || contractAddress}\n`;
      if (tokenInfo.symbol) {
        summary += `Symbol: ${tokenInfo.symbol}\n`;
      }
      summary += `Function: ${functionName}\n`;
      if (args.length > 0) {
        summary += `Args: ${args.join(', ')}\n`;
      }
      summary += `Result: ${humanReadable}\n`;
      summary += `Network: ${chain.name}\n`;
      summary += `Explorer: ${networkConfig.explorerUrl}/address/${contractAddress}`;

      yield {
        type: 'artifact',
        name: 'summary.txt',
        content: summary,
        mimeType: 'text/plain',
      };

      yield {
        type: 'result',
        data: output,
      };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      yield {
        type: 'error',
        message: `Contract call failed: ${errorMessage}. Make sure the function exists and arguments are correct.`,
      };
    }
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error occurred';
    yield { type: 'error', message: `Query failed: ${errorMessage}` };
  }
}
