# Delegated Agent Payment Demo

This project demonstrates a "Human-Not-Present" (delegated) payment flow, inspired by the [AP2 Protocol](https://ap2-protocol.org/) and its [x402 enhancement](https://ap2-protocol.org/topics/ap2-and-x402/). It combines an off-chain, user-signed `IntentMandate` with a merchant-signed `CartMandate` and an on-chain `PaymentFacilitator` contract. This allows an AI agent to execute a purchase on a user's behalf within a set of pre-approved, tamper-proof rules.

The user performs a one-time, on-chain setup (deploying a proxy and approving tokens). The final purchase is executed by the agent (a "facilitator") who pays the gas, without requiring the user to be online. The x402-style signed cart prevents the agent from modifying the payment details (e.g., amount or recipient).

## Project Structure

```bash
.
├── Makefile             # Automates all tasks (compile, gen-bindings, run)
├── README.md            # This file
├── config.toml          # Configuration file
├── contracts/
│   ├── PaymentFacilitator.sol # The user's on-chain proxy/vault
│   ├── TokenUSDC.sol      # A simple ERC20 token for the demo
│   └── test/
│       └── PaymentFacilitator.t.sol # Foundry tests
├── go.mod
├── go.sum
├── pkg/
│   ├── chain/
│   │   ├── bindings/      # (Generated) Go bindings for smart contracts
│   │   └── client.go      # Helper to connect to an Ethereum node
│   ├── config/
│   │   └── config.go      # Configuration loader
│   ├── signing/
│   │   └── eip712.go      # Logic for EIP-712 signing (Intent & Cart)
│   └── types/
│       └── types.go       # Go structs for Mandates and Payloads
├── cmd/
│   ├── user/              # (Phase 1) User's setup script
│   │   └── main.go
│   ├── merchant/          # (Phase 2a) Merchant server
│   │   └── main.go
│   └── agent/             # (Phase 2b) Agent's monitoring/execution script
│       └── main.go
└── deployments/           # (Generated) Stores addresses and task data
    ├── contracts.json
    └── task.json
```

## How it Works

### Security Model

This demo uses a dual-signature mechanism (user and merchant) to create a secure, delegatable payment:

1.  **User Intent**: The user signs an `IntentMandate`, defining *what* they are willing to spend (`maxPrice`, `token`) and *why* (`task`). This is their permission slip.
2.  **Merchant Cart**: The merchant signs a `CartMandate`, defining the *actual* payment details (`amount`, `merchant` address). This is the bill.
3.  **Agent Execution**: The agent is an untrusted facilitator. It fetches both signed mandates and presents them to the on-chain `PaymentFacilitator` contract.
4.  **On-Chain Verification**: The contract is the single source of truth. It only executes the payment if **both** signatures are valid and all rules match (e.g., `cart.amount <= intent.maxPrice`). The agent cannot tamper with the cart without invalidating the merchant's signature.

### Phase 1: User Setup (`cmd/user`)

The user runs this script *once* while they are "awake".

1.  **Connects** to the blockchain.
2.  **Deploys** `TokenUSDC.sol` and mints 1,000 tokens to the user.
3.  **Deploys** `PaymentFacilitator.sol`, which is owned by the user.
4.  **Approves (On-Chain):** The user sends an on-chain `approve` transaction to the `TokenUSDC` contract, allowing their *own* `PaymentFacilitator` to spend up to 50 USDC on their behalf.
5.  **Signs IntentMandate (Off-Chain):** The user defines their rules (e.g., "buy for <= 50 USDC") and signs this as an EIP-712 message. This signature is the agent's "permission slip".
6.  **Saves Artifacts:** The script saves contract addresses and the signed mandate to the `deployments/` folder for the agent to use.

### Phase 2a: Merchant Server (`cmd/merchant`)

The merchant runs a simple server that simulates an e-commerce backend.

1.  **Listens** on an HTTP endpoint (e.g., `/cart`).
2.  **Generates Cart:** When requested, it creates a `Cart` with the payment details (amount, token, merchant address).
3.  **Signs Cart:** It signs the `Cart` using its private key, creating a `cartSignature`.
4.  **Serves Payload:** It returns the `Cart` and `cartSignature` as a JSON payload.

### Phase 2b: Agent Execution (`cmd/agent`)

The agent runs this script while the user is "asleep".

1.  **Loads Artifacts:** Reads the `deployments/` folder to get contract addresses and the user's signed `IntentMandate`.
2.  **Monitors:** Simulates monitoring for a price drop.
3.  **Fetches Signed Cart:** Once the "price is right" (49 USDC), it calls the merchant's `/cart` endpoint to get the signed cart payload.
4.  **Executes (On-Chain):** The agent calls `executePurchase` on the `PaymentFacilitator` contract, providing the `IntentMandate`, `CartMandate`, the user's signature, and the merchant's signature. The agent pays the gas for this call.
5.  **Contract Validates:** The `PaymentFacilitator` contract performs all security checks on-chain:
    a. Verifies the user's signature against the `IntentMandate`.
    b. Verifies the merchant's signature against the `CartMandate`.
    c. Checks that the nonce hasn't been used.
    d. Checks that `cart.amount` (49 USDC) is less than or equal to `intent.maxPrice` (50 USDC).
    e. Checks that the tokens in the intent and cart match.
6.  **Contract Pays:** If all checks pass, the contract calls `transferFrom` on the `TokenUSDC` contract, pulling 49 USDC from the user's wallet and sending it to the merchant.

## Requirements

1.  **Go** (v1.21+)
2.  **Foundry:** A smart contract development toolchain.
    ```bash
    curl -L https://foundry.paradigm.xyz | bash && foundryup
    ```
    This will install `forge`, `cast`, and `anvil`.

## Steps to Run the Demo

### 1. Start Your Local Testnet

In a separate terminal, start `anvil`. This will simulate the Ethereum blockchain.

```bash
make anvil
```

Anvil will start and print a list of private keys. We will use the private keys for the first three default accounts in your `config.toml` file.

The RPC URL will be `http://127.0.0.1:8545`.

### 2. Configure Private Keys

Copy the private keys from the `anvil` output into your `config.toml` file.

-   **USER_PRIVATE_KEY:** The key for Account #0.
-   **AGENT_PRIVATE_KEY:** The key for Account #1.
-   **MERCHANT_PRIVATE_KEY:** The key for Account #2.

### 3. Install Dependencies and Build

This single command will install dependencies and compile all contracts and Go binaries.

```bash
make build
```

### 4. Run the Full Demo

This command will run the entire demo flow in one go:

```bash
make run-agent
```

This will:
1.  Run the user setup script (`cmd/user`).
2.  Start the merchant server in the background (`cmd/merchant`).
3.  Run the agent script (`cmd/agent`).

**Success!** You will see the merchant server logging the request, the agent logging the successful execution, and the `anvil` terminal showing the final `executePurchase` transaction.

## Testing

The project includes a Foundry test suite for the smart contracts and Go tests for the merchant server.

To run all tests, use the following command:

```bash
make test
```