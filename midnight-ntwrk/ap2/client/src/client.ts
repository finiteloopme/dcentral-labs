import axios from 'axios';
import { WalletBuilder } from '@midnight-ntwrk/wallet';
import { Wallet } from '@midnight-ntwrk/wallet-api';
import { NetworkId } from '@midnight-ntwrk/zswap';

const API_URL = 'http://localhost:8000';

async function main() {
  try {
    const response = await axios.post(`${API_URL}/api/predict`, { query: 'test' });
    console.log(response.data);
  } catch (error: any) {
    if (error.response && error.response.status === 402) {
      const wwwAuthenticateHeader = error.response.headers['www-authenticate'];
      const invoiceId = wwwAuthenticateHeader.match(/invoice="(.*?)"/)[1];

      console.log(`Payment required. Invoice ID: ${invoiceId}`);

      const wallet = await createWallet();

      const paymentOffer = await wallet.transferTransaction([
        {
          address: 'recipient-address', // The address of the API provider
          amount: 1_000_000, // 1 NIGHT token
          asset: 'NIGHT',
        },
      ]);

      const metadataOffer = await wallet.transferTransaction([
        {
          address: invoiceId, // Use the invoice ID as the address
          amount: 0,
          asset: 'NIGHT',
        },
      ]);

      const txToProve = paymentOffer.transaction.merge(metadataOffer.transaction);

      const provenTx = await wallet.proveTransaction({ type: 'TransactionToProve', transaction: txToProve });
      const txId = await wallet.submitTransaction(provenTx);

      console.log(`Transaction submitted with ID: ${txId.value}`);

      const preimage = txId.value.split('').reverse().join('');
      const l402Token = `${txId.value}:${preimage}`;

      try {
        const response = await axios.post(
          `${API_URL}/api/predict`,
          { query: 'test' },
          {
            headers: {
              Authorization: `L402 ${l402Token}`,
            },
          }
        );
        console.log(response.data);
      } catch (error: any) {
        console.error(error.response.data);
      }
    } else {
      console.error(error.message);
    }
  }
}

async function createWallet(): Promise<Wallet> {
  const indexerUri = 'http://localhost:8080';
  const indexerWsUri = 'ws://localhost:8080';
  const proverServerUri = 'http://localhost:7070';
  const substrateNodeUri = 'ws://localhost:9944';
  const seed = '0x0000000000000000000000000000000000000000000000000000000000000000';
  const networkId = NetworkId.UNDEPLOYED;

  return WalletBuilder.build(
    indexerUri,
    indexerWsUri,
    proverServerUri,
    substrateNodeUri,
    seed,
    networkId
  );
}

main();
