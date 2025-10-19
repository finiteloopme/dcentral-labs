import express, { Request, Response } from 'express';
import { indexerPublicDataProvider } from '@midnight-ntwrk/midnight-js-indexer-public-data-provider';
import { FinalizedTxData } from '@midnight-ntwrk/midnight-js-types';

const app = express();
app.use(express.json());

const QUERY_URL = process.env.MIDNIGHT_QUERY_URL || 'http://localhost:4000/graphql';
const SUBSCRIPTION_URL = process.env.MIDNIGHT_SUBSCRIPTION_URL || 'ws://localhost:4000/graphql';

const publicDataProvider = indexerPublicDataProvider(QUERY_URL, SUBSCRIPTION_URL);

app.post('/verify', async (req: Request, res: Response) => {
  const { tx_id } = req.body;

  try {
    const transaction: FinalizedTxData = await publicDataProvider.watchForTxData(tx_id);
    console.log(transaction);

    if (transaction) {
      res.json({ verified: true });
    } else {
      res.json({ verified: false });
    }
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

const port = process.env.PORT || 8002;
app.listen(port, () => {
  console.log(`Midnight Verifier listening on port ${port}`);
});
