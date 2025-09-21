# Delegated Agent Payment (AP2 + Proxy) Demo

This project demonstrates the "Human-Not-Present" (delegated) payment flow as discussed. It combines an off-chain AP2-style IntentMandate with an on-chain AgentProxy smart contract to allow an AI agent to execute a purchase on a user's behalf, within a set of pre-approved rules.

The user is only required to perform a one-time, on-chain setup (deploying a proxy and approving tokens). The final purchase is executed by the agent (a "facilitator") who pays the gas, without requiring the user to be online.

## Project Structure

```bash
. \
├── Makefile             # Automates all tasks (compile, gen-bindings, run) \
├── README.md            # This file \
├── config.toml          # Configuration file \
├── contracts/ \
│   ├── AgentProxy.sol     # The user's on-chain proxy/vault \
│   ├── TokenUSDC.sol      # A simple ERC20 token for the demo
├── go.mod \
├── go.sum \
├── build/                 # (Generated) Compiled contract ABI/BIN \
├── pkg/ \
│   ├── chain/ \
│   │   ├── bindings/      # (Generated) Go bindings for smart contracts \
│   │   │   ├── agentproxy.go \
│   │   │   └── tokenusdc.go \
│   │   └── client.go      # Helper to connect to an Ethereum node \
│   ├── signing/ \
│   │   └── eip712.go      # Logic for signing the EIP-712 IntentMandate \
│   └── types/ \
│       └── types.go       # Go structs for Mandates \
├── cmd/ \
│   ├── user_setup/        # (Phase 1) User's setup script \
│   │   └── main.go \
│   └── agent/             # (Phase 2) Agent's monitoring/execution script \
│       └── main.go \
└── deployments/           # (Generated) Stores addresses and task data \
    ├── contracts.json \
    └── task.json \
```

## How it Works

### Phase 1: User Setup (`cmd/user`)

The user runs this script *once* while they are "awake".

1. **Connects** to the blockchain.
2. **Deploys** TokenUSDC.sol and mints 1,000 tokens to the user.
3. **Deploys** AgentProxy.sol, which is owned by the user.
4. **Approves (On-Chain):** The user sends an on-chain approve transaction to the MockUSDC contract, allowing their *own* AgentProxy to spend up to 50 USDC on their behalf.
5. **Signs IntentMandate (Off-Chain):** The user defines their rules (e.g., "buy for &lt;= 50 USDC") and signs this as an EIP-712 message. This signature is the agent's "permission slip".
6. **Saves Artifacts:** The script saves contract addresses and the signed mandate to the deployments/ folder for the agent to use.

### Phase 2: Agent Execution (`cmd/agent`)

The agent runs this script while the user is "asleep".

1. **Loads Artifacts:** Reads the deployments/ folder to get contract addresses and the user's signed IntentMandate.
2. **Monitors:** Simulates monitoring for a price drop.
3. **Creates Cart:** Once the "price is right" (49 USDC), it creates a CartMandate.
4. **Executes (On-Chain):** The agent (as a facilitator) calls the executePurchase function on the AgentProxy contract. It pays the gas for this call.
5. Proxy Validates: The AgentProxy contract does all the security checks on-chain:
   a. Verifies the user's IntentMandate signature.
   b. Checks that the nonce hasn't been used.
   c. Checks that the cart.amount (49 USDC) is less than or equal to the intent.maxPrice (50 USDC).
6. **Proxy Pays:** If all checks pass, the proxy calls transferFrom on the MockUSDC contract, pulling 49 USDC from the user's wallet and sending it to the merchant.

## Testing

The project includes a Foundry test suite for the smart contracts.

To run the tests, use the following command:

```bash
make test-contracts
```

## Requirements

1. **Go** (v1.21+)
2. **Solidity Compiler** (solc, v0.8.20+)
3. **abigen:** Part of the go-ethereum toolkit.

   ```bash
   go install [github.com/ethereum/go-ethereum/cmd/abigen@latest](https://github.com/ethereum/go-ethereum/cmd/abigen@latest)
   ```

4. **Foundry:** A smart contract development toolchain.

   ```bash
   curl -L [https://foundry.paradigm.xyz](https://foundry.paradigm.xyz) | bash foundryup
   ```

   This will install `forge`, `cast`, and `anvil`.

## Steps to Run the Demo

### 1. Start Your Local Testnet

In a separate terminal, start `anvil`. This will simulate the Ethereum blockchain.

Anvil will start and print a list of private keys. We will use:

* **Account 0 (User):** `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`
* **Account 1 (Agent/Facilitator):** `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d`
* **Account 2 (Merchant):** `0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a`

The RPC URL will be [http://127.0.0.1:8545](http://127.0.0.1:8545).

### 2. Install Dependencies

This will install go-ethereum.

```bash
make install-deps
```

### 3. Build the Project

This single command will compile the Solidity code, generate the Go bindings, and compile the Go code.

```bash
make build
```

(Optional) To update the smart contract dependencies (e.g. OpenZeppelin), run:
```bash
make update-forge-deps
```

### 4. Run Phase 1: User Setup

Run the user's setup script. This will build the binaries and then run the user setup.

```bash
make run-user-setup
```

You will see output in your terminal, and anvil will show new transactions.

### 5. Run Phase 2: Agent Execution

Now, run the agent. This will build the binaries and then run the agent.

```bash
make run-agent
```

**Success!** You will see the agent's output, and the anvil terminal will show the final executePurchase transaction. You can check the anvil logs to see that the MockUSDC balance was transferred from the user to the merchant, all while the user was "asleep".
