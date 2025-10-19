Your task is to create a minimum viable product for the following use case.
Deliverables as part of this MVP:
1. `Makefile` to simplify operational tasks
2. `README.md` which highlights project structure and overview of the components and how they align with the use case
3. Each component developed as a micro service with their own Dockerfile
4. Local build of all the components should not leverage Docker
5. Remote build of all components should leverage Google Cloud Build configuration
6. Remote deployment target should be Cloud Run.  A separate Cloud Build configuration should manage this deployment pipeline

# Use Case: Confidential AI Financial Analyst API

## Overview
A service that provides access to a sophisticated AI model trained on proprietary financial data, market sentiment, and private trading strategies. Clients (e.g., hedge funds, analysts, autonomous agents) can query this model for high-value insights. The integration of x402 and Midnight ensures that both the user's identity and their sensitive queries remain completely private.

## The Problem
Financial strategy is confidential. A user querying an AI model about a potential merger or market risk does not want their query or their identity exposed on a public ledger. This exposure could leak their strategy to competitors.

## The Flow
1.  **The Request:** An analyst's software or an AI agent makes an API call to the AI model with a sensitive query.
    - `POST /api/predict`
    - `Body: {"query": "Analyze risk profile for a merger between Company A and B"}`

2.  **The Payment Wall (x402):** The server denies the initial request and responds with a `402 Payment Required` error. The `WWW-Authenticate` header contains the payment details, including the price and a unique invoice ID for the transaction.

3.  **The Private Payment (Midnight):** The client's wallet constructs and executes a transaction on the Midnight network to pay the required fee.
    - **Confidentiality:** The transaction details (sender, receiver, amount) are shielded by Midnight's ZK-privacy features.
    - **Metadata:** The transaction includes the unique invoice ID from the server in its metadata to link the payment to the specific API request.

4.  **The Proof and Access:** The client retries the API request, this time including the Midnight transaction ID in the `Authorization` header as proof of payment.
    - `Authorization: L402 <midnight_tx_id>:<preimage>`

5.  **Verification and Response:** The server's backend privately verifies the transaction on the Midnight network. Upon confirmation, it grants access, processes the confidential query, and returns the AI-generated financial report to the client.
