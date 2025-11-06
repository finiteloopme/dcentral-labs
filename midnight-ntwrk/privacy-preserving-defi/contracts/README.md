# Smart Contracts

This directory contains the smart contracts for the Privacy-Preserving DeFi platform.

## Structure

```
contracts/
├── src/                    # Main contract source files
│   ├── MockUSDC.sol        # Mock USDC token for testing
│   ├── DeFiVault.sol        # Main vault contract for deposits
│   ├── ComplianceRegistry.sol # Compliance checking contract
│   ├── PrivateLedger.compact # Midnight compact ledger format
│   ├── Counter.sol          # Simple counter for testing
│   └── ...
├── script/                 # Foundry deployment scripts
│   ├── Counter.s.sol       # Script for deploying Counter
│   └── Deploy.s.sol       # Main deployment script
├── test/                  # Foundry test files
│   └── Counter.t.sol      # Counter contract tests
├── foundry.toml          # Foundry configuration
└── README.md             # This file
```

## Main Contracts

### MockUSDC.sol
- ERC20 token contract for testing USDC functionality
- Mintable by owner for testing purposes
- Used as the base asset for deposits

### DeFiVault.sol
- Main vault for handling user deposits
- Integrates with compliance registry
- Supports ZK proof verification
- Manages total value locked (TVL)

### ComplianceRegistry.sol
- Registry for compliant user addresses
- Manages risk levels and limits
- Used by DeFiVault for compliance checks

## Deployment

Use the deployment scripts in the `script/` directory:

```bash
# Deploy all contracts
forge script script/Deploy.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast

# Deploy a specific contract
forge script script/Counter.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

## Testing

Run tests using Foundry:

```bash
# Run all tests
forge test

# Run a specific test
forge test --match-test testCounter
```

## Configuration

- `foundry.toml` contains the Foundry configuration
- `addresses.json` contains deployed contract addresses
- Update these files for your specific deployment environment

---

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```