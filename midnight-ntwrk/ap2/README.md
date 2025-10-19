# Confidential AI Financial Analyst API

This project is a minimum viable product (MVP) of a confidential AI financial analyst API. It demonstrates how to use [x402](https://github.com/lightningnetwork/l402) and [Midnight](https://www.midnight.network/) to create a private, pay-per-use API.

## Project Structure

The project is composed of three microservices:

*   `api-gateway`: The main entry point for the user. It handles the x402 payment wall and forwards requests to the `analyst-api`.
*   `analyst-api`: The service that processes the user's query. It simulates the confidential processing of a sophisticated AI model.
*   `midnight-verifier`: A service that verifies the Midnight transaction and returns a preimage that the `api-gateway` can use to validate the payment.

## How it Works

1.  The user makes a request to the `api-gateway`.
2.  The `api-gateway` returns a `402 Payment Required` error with a unique invoice ID.
3.  The user pays the invoice using a Midnight transaction, including the invoice ID in the transaction metadata.
4.  The user retries the request to the `api-gateway`, this time with the Midnight transaction ID in the `Authorization` header.
5.  The `api-gateway` calls the `midnight-verifier` to verify the transaction.
6.  The `midnight-verifier` confirms the transaction on the Midnight network and returns a preimage.
7.  The `api-gateway` uses the preimage to verify the payment and then forwards the request to the `analyst-api`.
8.  The `analyst-api` processes the request and returns the result to the user.

## Getting Started

### Prerequisites

*   [Docker](https.docs.docker.com/get-docker/)
*   [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
*   [make](https://www.gnu.org/software/make/)

### Local Development

To build and run the services locally, run the following command:

```bash
make local-run
```

This will start all three services. You can then make requests to the `api-gateway` at `http://localhost:8000`.

### Client

To run the client script, you will need to have Node.js and npm installed.

Then, run the following commands:

```bash
cd client
npm install
npm run build
node dist/client.js
```

**Note:** The client script uses placeholder URIs for the Midnight network services and a placeholder seed. You will need to replace these with actual values to run the client against a real Midnight network.

### Remote Deployment

To deploy the services to Cloud Run, you will need to have a Google Cloud project and have the `gcloud` CLI configured.

Then, run the following command:

```bash
make remote-deploy
```

This will build and deploy all three services to Cloud Run.
