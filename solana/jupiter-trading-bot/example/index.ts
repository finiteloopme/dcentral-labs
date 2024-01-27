import { createJupiterApiClient, DefaultApi, IndexedRouteMapResponse, QuoteResponse, SwapResponse } from "../src/index";
import { Connection, Keypair, PublicKey, sendAndConfirmTransaction, TransactionExpiredTimeoutError, VersionedTransaction } from "@solana/web3.js";
import { Wallet } from "@project-serum/anchor";
import bs58 from "bs58";

require("dotenv").config();

type RouteMap = Record<string, string[]>;

function inflateIndexedRouteMap(
  result: IndexedRouteMapResponse
): Record<string, string[]> {
  const { mintKeys, indexedRouteMap } = result;

  return Object.entries(indexedRouteMap).reduce<RouteMap>(
    (acc, [inputMintIndexString, outputMintIndices]) => {
      const inputMintIndex = Number(inputMintIndexString);
      const inputMint = mintKeys[inputMintIndex];
      if (!inputMint)
        throw new Error(`Could no find mint key for index ${inputMintIndex}`);

      acc[inputMint] = outputMintIndices.map((index) => {
        const outputMint = mintKeys[index];
        if (!outputMint)
          throw new Error(`Could no find mint key for index ${index}`);

        return outputMint;
      });

      return acc;
    },
    {}
  );
}

export async function getQuote(api: DefaultApi, fromTokenMint: string, toTokenMint: string, transferAmount: number) : Promise<QuoteResponse> {
  const quote: QuoteResponse = await api.quoteGet({
    inputMint: fromTokenMint,
    outputMint: toTokenMint,
    amount: transferAmount,
    slippageBps: 10,
    onlyDirectRoutes: false,
    asLegacyTransaction: false
  });

  if (!quote){
    console.error("Unable to fetch quote.");
  }

  return quote;
}

export async function swapPost(connection: Connection, api: DefaultApi, quote: QuoteResponse, wallet: Wallet) : Promise<string>{
  const swapResult: SwapResponse = await api.swapPost({
    swapRequest: {
      quoteResponse: quote,
      userPublicKey: wallet.publicKey.toBase58(),
      dynamicComputeUnitLimit: true,
    },
  });
  // console.dir(swapResult, { depth: null });
  return submitTxn(connection, swapResult.swapTransaction, wallet);
  // return swapResult.swapTransaction;
}

export async function submitTxn(connection: Connection, encodedSwapTxn: string, wallet: Wallet) : Promise<string>{
  // submit transaction
  const swapTransactionBuf = Buffer.from(encodedSwapTxn, "base64");
  var transaction = VersionedTransaction.deserialize(swapTransactionBuf);
  // console.log(transaction);

  // sign the transaction
  transaction.sign([wallet.payer]);

  const rawTransaction = transaction.serialize();
  const txid = await connection.sendRawTransaction(rawTransaction, {
    skipPreflight: true,
    maxRetries: 2,
  });
  console.log(`Submitted txn: https://solscan.io/tx/${txid}`);
  try {
    await connection.confirmTransaction(txid);
    console.log(`Txn confirmed. https://solscan.io/tx/${txid}`);
  } catch (e){
    if (e instanceof TransactionExpiredTimeoutError){
      console.log("Txn confirmation timed out. https://solscan.io/tx/" + txid);
    }
  }
  // sendAndConfirmRawTransaction(connection,rawTransaction);
  return txid;
}

export async function main() {
  const jupiterQuoteApi = createJupiterApiClient();
  // console.log("Key: " + process.env.PRIVATE_KEY);
  const wallet = new Wallet(
    Keypair.fromSecretKey(bs58.decode(process.env.WALLET_PRIVATE_KEY || ""))
  );

  // make sure that you are using your own RPC endpoint
  const connection = new Connection(
    "https://muddy-sly-thunder.solana-mainnet.quiknode.pro/7e368a1cb0b454d6f0fe9f062f26acf24a013882/"
  );

  const usdcMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v";
  const solMint = "So11111111111111111111111111111111111111112";

  const usdc_amt = 5; // 5 USDC
  const usdc_to_swap = usdc_amt * 1_000_000; // In lamports

  // get quotes
  const usdc2solQuote: QuoteResponse = await getQuote(
                                                        jupiterQuoteApi, 
                                                        usdcMint, 
                                                        solMint, 
                                                        usdc_to_swap
                                                      );
  const quotedSOL = Number(usdc2solQuote.outAmount);

  const sol2usdcQuote: QuoteResponse = await getQuote(
                                                        jupiterQuoteApi, 
                                                        solMint, 
                                                        usdcMint, 
                                                        quotedSOL
                                                      );
  const quotedUSDC = Number(sol2usdcQuote.outAmount);
  
  // async ()=>{
    console.log("USDC to SOL: " + quotedSOL/1_000_000_000);
    console.log("SOL to USDC: " + quotedUSDC/1_000_000);
  // }

  if ((quotedUSDC - usdc_to_swap) > 2_000){ //2c
    // get serialized transaction
    console.log("Submiting USDC to SOL Txn");
    const usdc2solSwapResult = swapPost(connection, jupiterQuoteApi, usdc2solQuote, wallet);
    // get serialized transaction
    console.log("Submiting SOL to USDC Txn");
    const sol2usdcSwapResult = swapPost(connection, jupiterQuoteApi, sol2usdcQuote, wallet);
    Promise.all([usdc2solSwapResult, sol2usdcSwapResult]).then((values) => {
      // const txn = String(values)
      // return submitTxn(connection, txn, wallet);
      console.log("USDC to SOL txid: " + JSON.stringify(usdc2solSwapResult));
      console.log("SOL to USDC txid: " + JSON.stringify(sol2usdcSwapResult));
      console.log("Should see a profit of: " + (quotedUSDC-usdc_to_swap)/1_000_000);
    });    
  }

  // // // get route map
  // // const result = await jupiterQuoteApi.indexedRouteMapGet();
  // // const routeMap = inflateIndexedRouteMap(result);
  // // console.log(Object.keys(routeMap).length);
}

// async function callMainInLoop() {
//   while(true){
//     await main();
//   }
// }

// callMainInLoop();
main();