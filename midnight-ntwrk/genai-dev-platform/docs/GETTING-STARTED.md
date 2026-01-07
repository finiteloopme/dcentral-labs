# Getting Started with Midnight Development

> A hands-on guide to explore the Midnight GenAI Development Platform  
> **Estimated time:** 35-45 minutes

Welcome to Midnight! This guide will walk you through the complete development workflow—from creating wallets and managing tokens to building and deploying smart contracts. By the end, you'll have a solid understanding of what the platform offers and how to use the `midnightctl` CLI.

---

## What You'll Learn

- Use the OpenCode AI assistant for Midnight development
- How to use the `midnightctl` command-line interface
- Create and manage wallets for NIGHT tokens and DUST resources
- Build, compile, and deploy a smart contract using Compact
- Monitor services and understand chain environments

## Prerequisites

This guide assumes:

- You have access to a Midnight development environment (Cloud Workstation)
- The Midnight services (node, indexer, proof-server) are already running
- You're ready to explore!

---

## Launching the Terminal

To get started, open a terminal in your development environment.

**In Code OSS (VS Code):**

1. Press `` Ctrl+` `` (backtick) to toggle the integrated terminal
2. Or use the menu: **Terminal → New Terminal**

Once the terminal opens, verify your environment:

```bash
$ welcome

================================================================================
                    Midnight Development Environment
================================================================================

Services:
  Midnight Node:   ws://midnight-node:9944
  Proof Server:    http://proof-server:6300
  Indexer:         http://indexer:8088/api/v1/graphql

Tools:
  compact:         0.18.0
  node:            v20.x.x
  midnightctl:     1.0.0

Quick Commands:
  midnightctl init <name>      Create a new project
  midnightctl compile          Compile Compact contracts
  midnightctl services status  Check service health

Run 'welcome' anytime to see this message.
================================================================================
```

> **Tip:** Run `welcome` anytime to see service URLs and available tools.

---

## Part 1: Your Development Environment

**Estimated time:** ~5 minutes

### 1.1 Check Service Health

Verify that all Midnight services are running:

```bash
$ midnightctl services status

Midnight Services Status
========================

  Service        Status    Endpoint
  ─────────────────────────────────────────────────────
  node           healthy   ws://midnight-node:9944
  indexer        healthy   http://indexer:8088/api/v1/graphql
  proof-server   healthy   http://proof-server:6300

All services are running.
```

If any service shows as unhealthy, contact your platform administrator.

### 1.2 View Service URLs

Get the URLs for each service:

```bash
$ midnightctl services urls

Service URLs
============
  Node (WebSocket):   ws://midnight-node:9944
  Indexer (GraphQL):  http://indexer:8088/api/v1/graphql
  Proof Server:       http://proof-server:6300
```

**What each service does:**

| Service | Purpose |
|---------|---------|
| **Node** | Midnight blockchain node - submits transactions, queries state |
| **Indexer** | GraphQL API for querying blockchain data (balances, transactions) |
| **Proof Server** | Generates zero-knowledge proofs for private transactions |

### 1.3 Check Your Environment

See which chain environment you're connected to:

```bash
$ midnightctl env show

Current Environment
===================
  Chain:     standalone
  Network:   Local development network
```

The `standalone` environment is a local development chain—perfect for learning and testing.

---

## Part 2: Your AI Assistant

**Estimated time:** ~5 minutes

The platform includes **OpenCode**, an AI coding assistant pre-loaded with Midnight knowledge. It can help you write Compact code, understand concepts, and troubleshoot issues throughout your development workflow.

### 2.1 Launch OpenCode

Start the interactive terminal UI:

```bash
$ opencode
```

You'll see a chat interface where you can type questions and get instant help.

### 2.2 Try These Prompts

Type each prompt and press Enter to see Midnight-specific responses:

**Understand the basics:**
```
What is Midnight and how does it differ from other blockchains?
```

**Learn about tokens:**
```
What's the difference between shielded and unshielded NIGHT?
```

**Get coding help:**
```
Show me a simple Compact contract example
```

### 2.3 Exit OpenCode

When you're ready to continue, press `Ctrl+C` to exit and return to your terminal.

> **Tip:** For quick one-off questions without entering the TUI, use:
> ```bash
> $ opencode run "your question here"
> ```

Now that you know how to get AI assistance, let's explore the CLI tools.

---

## Part 3: The midnightctl CLI

**Estimated time:** ~3 minutes

The `midnightctl` CLI is your primary tool for Midnight development. Let's explore its structure.

### 3.1 CLI Overview

View all available commands:

```bash
$ midnightctl --help

Usage: midnightctl <command> [options]

Commands:
  init <name>       Create a new Midnight project
  compile           Compile Compact smart contracts
  wallet            Manage wallets (NIGHT tokens and DUST resources)
  contract          Deploy and interact with contracts
  services          Manage Midnight development services
  env               Environment management

Options:
  -h, --help        Show help
  -v, --version     Show version
```

### 3.2 Command Groups

| Command Group | Purpose |
|---------------|---------|
| `init` | Scaffold a new Midnight project |
| `compile` | Compile Compact contracts to deployable bytecode |
| `wallet` | Create wallets, check balances, send tokens |
| `contract` | Deploy compiled contracts |
| `services` | Check service status, view logs |
| `env` | View and switch chain environments |

### 3.3 Getting Help

Every command has built-in help. Use `--help` on any command:

```bash
$ midnightctl wallet --help

Usage: midnightctl wallet <command> [options]

Commands:
  create <name>       Create a new wallet with generated mnemonic
  import <name>       Import a wallet from seed or mnemonic
  list                List all wallets
  address [name]      Show wallet addresses
  balance [name]      Check wallet balance
  fund <name> <amt>   Fund wallet from genesis (standalone only)
  send <from> <to> <amt>  Send NIGHT tokens
  register-dust       Register for DUST generation
  set-default <name>  Set default wallet
  remove <name>       Remove a wallet
```

---

## Part 4: Wallet Operations

**Estimated time:** ~10 minutes

Before deploying contracts or sending transactions, you need a funded wallet. Let's walk through the complete wallet workflow.

### 4.1 Understanding the Token Model

Midnight has two tokens:

| Token | Description | Transferable |
|-------|-------------|--------------|
| **NIGHT** | Native token for value transfer | Yes |
| **DUST** | Fee resource for transactions | No (regenerates) |

NIGHT can exist in two forms:

| Form | Address Prefix | Privacy |
|------|----------------|---------|
| **Unshielded** | `mn_addr_...` | Public on-chain |
| **Shielded** | `mn_shield-addr_...` | Private (ZK proofs) |

### 4.2 Quick Start: Import a Genesis Wallet

In standalone mode, several genesis wallets are pre-funded for development. Let's import one:

```bash
$ midnightctl wallet import genesis-1 --seed 0000000000000000000000000000000000000000000000000000000000000001

Wallet 'genesis-1' imported successfully.

Addresses:
  Unshielded:  mn_addr_standalone1qpzry9x8gf2tvdw0s3jn54khce6mua7l...
  Shielded:    mn_shield-addr_standalone1qpzry9x8gf2tvdw0s3jn54k...
  DUST:        mn_dust_standalone1qpzry9x8gf2tvdw0s3jn54khce6mua7l...
```

> **Note:** Genesis wallets use simple seeds and are only available in standalone/devnet modes.  
> - `0000000000000000000000000000000000000000000000000000000000000001`  
> - `0000000000000000000000000000000000000000000000000000000000000002`  
> - `0000000000000000000000000000000000000000000000000000000000000003`  
> - `0000000000000000000000000000000000000000000000000000000000000004`  

### 4.3 Check Wallet Balance

See how much NIGHT the genesis wallet has:

```bash
$ midnightctl wallet balance genesis-1

Wallet Balance: genesis-1
=========================
  Shielded NIGHT:    1,000,000.00
  Unshielded NIGHT:  1,000,000.00
  ─────────────────────────────
  Total NIGHT:       2,000,000.00
```

To include DUST resource status:

```bash
$ midnightctl wallet balance genesis-1 --include-dust

Wallet Balance: genesis-1
=========================
  Shielded NIGHT:    1,000,000.00
  Unshielded NIGHT:  1,000,000.00
  ─────────────────────────────
  Total NIGHT:       2,000,000.00

  DUST:              100.00 (regenerating)
```

### 4.4 View Wallet Addresses

Display all addresses for a wallet:

```bash
$ midnightctl wallet address genesis-1

Wallet Addresses: genesis-1
===========================
  Unshielded:  mn_addr_standalone1qpzry9x8gf2tvdw0s3jn54khce6mua7l...
  Shielded:    mn_shield-addr_standalone1qpzry9x8gf2tvdw0s3jn54k...
  DUST:        mn_dust_standalone1qpzry9x8gf2tvdw0s3jn54khce6mua7l...
```

Use the `--all` flag for the full address (not truncated).

### 4.5 Create Your Own Wallet

Now let's create a fresh wallet with a generated mnemonic:

```bash
$ midnightctl wallet create my-wallet

Wallet 'my-wallet' created successfully.

Mnemonic (24 words):
====================
  1. abandon    2. ability    3. able       4. about
  5. above      6. absent     7. absorb     8. abstract
  9. absurd    10. abuse     11. access    12. accident
 13. account   14. accuse    15. achieve   16. acid
 17. acoustic  18. acquire   19. across    20. act
 21. action    22. actor     23. actress   24. actual

WARNING: Store this mnemonic securely. Anyone with these words
can control your wallet. Never share it with anyone.

Addresses:
  Unshielded:  mn_addr_standalone1abc123...
  Shielded:    mn_shield-addr_standalone1xyz789...
```

> **Important:** Save your mnemonic securely! It's the only way to recover your wallet.

### 4.6 List All Wallets

View all wallets you've created or imported:

```bash
$ midnightctl wallet list

Wallets
=======
  NAME        DEFAULT   ADDRESS (unshielded)
  genesis-1   no        mn_addr_standalone1qpzry9x8gf2tvdw0s3jn54k...
  my-wallet   no        mn_addr_standalone1abc123...
```

### 4.7 Fund Your Wallet

Transfer NIGHT from the genesis wallet to your new wallet:

```bash
$ midnightctl wallet fund my-wallet 1000

Funding Wallet
==============
  From:        Genesis Wallet #1
  To:          my-wallet
  Amount:      1,000 NIGHT

  Transaction: 0x9876543210abcdef...
  Status:      Confirmed

Wallet 'my-wallet' funded with 1,000 NIGHT.
```

Verify the balance:

```bash
$ midnightctl wallet balance my-wallet

Wallet Balance: my-wallet
=========================
  Shielded NIGHT:    0.00
  Unshielded NIGHT:  1,000.00
  ─────────────────────────────
  Total NIGHT:       1,000.00
```

### 4.8 Register for DUST Generation

DUST is required to pay transaction fees. Register your wallet to receive DUST:

```bash
$ midnightctl wallet register-dust

DUST Registration
=================
  Wallet:      my-wallet
  Transaction: 0xabcdef123456...
  Status:      Registered

Your wallet will now generate DUST based on your NIGHT holdings.
```

> **Note:** DUST regenerates over time proportional to your NIGHT balance. More NIGHT = faster DUST regeneration.

### 4.9 Send Tokens

Let's transfer NIGHT between wallets. First, create a second wallet to receive funds:

```bash
$ midnightctl wallet create my-wallet-2

Wallet 'my-wallet-2' created successfully.
...
```

Get the new wallet's unshielded address:

```bash
$ midnightctl wallet address my-wallet-2

Wallet Addresses: my-wallet-2
===========================
  Unshielded:  mn_addr_standalone1xyz789...
  ...
```

Now send NIGHT from your funded wallet to the new one:

```bash
$ midnightctl wallet send my-wallet mn_addr_standalone1xyz789... 100

Sending NIGHT
=============
  From:    my-wallet
  To:      mn_addr_standalone1xyz789...
  Amount:  100 NIGHT
  Type:    Unshielded Transfer

  Transaction: 0xfedc9876543210...
  Status:      Confirmed
```

Verify the transfer by checking the recipient's balance:

```bash
$ midnightctl wallet balance my-wallet-2

Wallet Balance: my-wallet-2
===========================
  Shielded NIGHT:    0.00
  Unshielded NIGHT:  100.00
  ─────────────────────────────
  Total NIGHT:       100.00
```

> **Note:** This guide covers unshielded transfers. For shielded (private) 
> transfers, you first need to shield your tokens. See 
> [WALLET-HOW-TO.md](../WALLET-HOW-TO.md) for shielding operations.

### 4.10 Set a Default Wallet

Set a default wallet to avoid specifying it in every command:

```bash
$ midnightctl wallet set-default my-wallet

Default wallet set to 'my-wallet'.
```

Now commands like `balance` and `address` will use `my-wallet` automatically:

```bash
$ midnightctl wallet balance

Wallet Balance: my-wallet (default)
===================================
  Shielded NIGHT:    0.00
  Unshielded NIGHT:  900.00
  ─────────────────────────────
  Total NIGHT:       900.00
```

---

## Part 5: Smart Contract Development

**Estimated time:** ~10 minutes

Now let's build and deploy a smart contract using Compact, Midnight's privacy-preserving smart contract language.

### 5.1 Create a New Project

Scaffold a new Midnight project:

```bash
$ midnightctl init my-counter-dapp

Creating project 'my-counter-dapp'...

  Created: my-counter-dapp/
  Created: my-counter-dapp/contracts/
  Created: my-counter-dapp/contracts/counter.compact
  Created: my-counter-dapp/src/
  Created: my-counter-dapp/src/index.ts
  Created: my-counter-dapp/tests/
  Created: my-counter-dapp/package.json
  Created: my-counter-dapp/tsconfig.json
  Created: my-counter-dapp/midnight.config.json
  Created: my-counter-dapp/.env

Installing dependencies...
Done!

Next steps:
  cd my-counter-dapp
  midnightctl compile
```

### 5.2 Explore the Project Structure

```bash
$ cd my-counter-dapp
$ ls -la

my-counter-dapp/
├── contracts/           # Compact smart contracts
│   └── counter.compact  # Example counter contract
├── src/                 # TypeScript source code
│   └── index.ts         # Main entry point
├── tests/               # Test files
│   └── counter.test.ts  # Example tests
├── build/               # Compiled output (after compile)
├── package.json         # Node.js dependencies
├── tsconfig.json        # TypeScript configuration
├── midnight.config.json # Midnight project settings
├── .env                 # Service URLs
└── .gitignore
```

### 5.3 Understand the Counter Contract

Open `contracts/counter.compact` to see the example contract:

```compact
// Counter - A simple Midnight smart contract example
pragma language_version >= 0.18.0;

// Ledger state - persisted on-chain
ledger counter: Counter;

// Counter state structure
struct Counter {
  value: Uint<64>;
}

// Increment the counter by 1
export circuit increment(): [] {
  counter = Counter { value: (counter.value + 1) as Uint<64> };
}

// Get the current counter value
export circuit get_value(): Uint<64> {
  return counter.value;
}
```

**Key Compact concepts:**

| Concept | Description |
|---------|-------------|
| `pragma` | Specifies the Compact language version |
| `ledger` | On-chain state that persists between calls |
| `struct` | Define data structures |
| `export circuit` | Public functions that can be called externally |
| `Uint<64>` | 64-bit unsigned integer type |

### 5.4 Compile the Contract

Compile the Compact contract to deployable bytecode:

```bash
$ midnightctl compile

Compiling Compact contracts...

  Compiling: contracts/counter.compact
  Output:    build/counter/

Compilation successful!

Build artifacts:
  build/counter/
  ├── contract.zkir      # Zero-knowledge intermediate representation
  ├── contract.wasm      # WebAssembly module
  └── contract.json      # Contract metadata & ABI
```

### 5.5 Deploy the Contract (Coming Soon)

> **Note:** Contract deployment is currently a work in progress. 
> Check back for updates or see the project repository for the latest status.

Once available, you'll be able to deploy your compiled contract with:

```bash
$ midnightctl contract deploy ./build/counter
```

---

## Part 6: Service Management

**Estimated time:** ~3 minutes

Learn how to monitor and manage the Midnight services.

### 6.1 View Service Logs

Check logs for troubleshooting:

**Node logs:**
```bash
$ midnightctl services logs node

[2025-01-07T10:15:32Z] INFO: Block #1234 produced
[2025-01-07T10:15:33Z] INFO: Transaction 0xabcd... included
...
```

**Indexer logs:**
```bash
$ midnightctl services logs indexer
```

**Proof server logs:**
```bash
$ midnightctl services logs proof
```

### 6.2 Understanding Chain Environments

Midnight supports multiple chain environments for different development stages:

| Environment | Description | Use Case |
|-------------|-------------|----------|
| `standalone` | Local dev network with ephemeral state | Learning, rapid iteration |
| `devnet` | Shared development network | Integration testing |
| `testnet` | Public test network | Pre-production testing |
| `mainnet` | Production network | Live deployments |

View your current environment:

```bash
$ midnightctl env show

Current Environment
===================
  Chain:     standalone
  Network:   Local development network
  
  Features:
    - Ephemeral state (resets on restart)
    - Pre-funded genesis wallets available
    - Fast block times for rapid testing
```

---

## What's Next?

Congratulations! You've explored the core capabilities of the Midnight development platform. Here's what to try next:

### Expand Your Knowledge

- **[WALLET-HOW-TO.md](../WALLET-HOW-TO.md)** - Advanced wallet operations, HD derivation, troubleshooting
- **[Midnight Documentation](https://docs.midnight.network)** - Official Midnight documentation
- **[Compact Language Guide](https://docs.midnight.network/compact)** - Deep dive into Compact

### Experiment

- Modify the counter contract to add a `decrement` function
- Create a token transfer contract
- Try shielding and unshielding NIGHT tokens
- Deploy to testnet when you're ready

### Get Help

- Use `opencode` to ask questions about Midnight concepts
- Check service logs if something isn't working
- Run `midnightctl <command> --help` for command-specific help

---

## Quick Reference Card

### Essential Commands

| Task | Command |
|------|---------|
| Check services | `midnightctl services status` |
| View service URLs | `midnightctl services urls` |
| View logs | `midnightctl services logs <node\|indexer\|proof>` |

### Wallet Commands

| Task | Command |
|------|---------|
| Create wallet | `midnightctl wallet create <name>` |
| Import wallet | `midnightctl wallet import <name> --seed <seed>` |
| List wallets | `midnightctl wallet list` |
| Check balance | `midnightctl wallet balance [name]` |
| View addresses | `midnightctl wallet address [name]` |
| Fund wallet | `midnightctl wallet fund <name> <amount>` |
| Send tokens | `midnightctl wallet send <from> <to> <amount>` |
| Register DUST | `midnightctl wallet register-dust` |
| Set default | `midnightctl wallet set-default <name>` |

### Development Commands

| Task | Command |
|------|---------|
| Create project | `midnightctl init <name>` |
| Compile contracts | `midnightctl compile` |
| Deploy contract | `midnightctl contract deploy <path>` |

### Environment Commands

| Task | Command |
|------|---------|
| Show environment | `midnightctl env show` |

### AI Assistant

| Task | Command |
|------|---------|
| Interactive mode | `opencode` |
| One-off question | `opencode run "<question>"` |

---

Happy building on Midnight!
