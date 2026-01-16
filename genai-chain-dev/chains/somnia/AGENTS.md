# Somnia Development Environment - AI Context

You are an AI assistant in a **Somnia blockchain development workstation**. Somnia is a high-performance EVM-compatible L1 blockchain optimized for gaming and metaverse applications.

## Network Information

| Property | Value |
|----------|-------|
| **Chain ID** | 50311 (Testnet) |
| **RPC URL** | https://dream-rpc.somnia.network |
| **Explorer** | https://somnia-testnet.socialscan.io |
| **Faucet** | https://faucet.somnia.network |
| **Native Token** | STT (Somnia Test Token) |
| **Consensus** | IceDB (novel multistream consensus) |
| **TPS Target** | 400,000+ |

## Available Tools

### CLI (`somniactl`)

```bash
# Project initialization
somniactl init <project-name>      # Scaffold Foundry project

# Contract development
somniactl compile                  # Compile contracts (forge build)
somniactl test                     # Run tests (forge test)
somniactl deploy <contract>        # Deploy contract
somniactl verify <address>         # Verify on explorer

# Wallet management
somniactl wallet create <name>     # Create new wallet
somniactl wallet import <name>     # Import from mnemonic/key
somniactl wallet list              # List all wallets
somniactl wallet balance [name]    # Check balance
somniactl wallet send <to> <amt>   # Send STT
somniactl wallet address [name]    # Show address
somniactl wallet export <name>     # Export private key
somniactl wallet remove <name>     # Remove wallet
somniactl wallet set-default <n>   # Set default wallet

# Local development
somniactl node start               # Start Anvil node
somniactl node stop                # Stop Anvil
somniactl node status              # Check status
somniactl node logs                # View logs

# Network management
somniactl network list             # List available networks
somniactl network current          # Show current network
```

### Foundry Toolchain

```bash
forge build                        # Compile contracts
forge test                         # Run tests
forge test -vvvv                   # Verbose test output
forge script <script>              # Run deployment scripts
forge verify-contract              # Verify on explorer

cast send <to> <sig> <args>        # Send transaction
cast call <to> <sig> <args>        # Read contract state
cast balance <address>             # Check balance
cast block                         # Get block info

anvil                              # Start local EVM node
anvil --fork-url <rpc>             # Fork from network
```

## Project Structure (Foundry)

```
my-project/
├── src/                           # Contract source files
│   └── Counter.sol
├── test/                          # Test files
│   └── Counter.t.sol
├── script/                        # Deployment scripts
│   └── Deploy.s.sol
├── lib/                           # Dependencies (git submodules)
├── out/                           # Build artifacts
├── foundry.toml                   # Foundry configuration
└── .env                           # Environment variables (not committed)
```

## Development Workflow

### 1. Create New Project

```bash
somniactl init my-game-contracts
cd my-game-contracts
```

### 2. Write Contracts

Create Solidity contracts in `src/`. Example:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GameToken {
    string public name = "Game Token";
    mapping(address => uint256) public balances;
    
    function mint(address to, uint256 amount) external {
        balances[to] += amount;
    }
}
```

### 3. Write Tests

```solidity
// test/GameToken.t.sol
import "forge-std/Test.sol";
import "../src/GameToken.sol";

contract GameTokenTest is Test {
    GameToken token;
    
    function setUp() public {
        token = new GameToken();
    }
    
    function test_Mint() public {
        token.mint(address(this), 100);
        assertEq(token.balances(address(this)), 100);
    }
}
```

### 4. Test Locally

```bash
# Start local node
somniactl node start

# Run tests
somniactl test
```

### 5. Deploy to Testnet

```bash
# Create and fund wallet
somniactl wallet create deployer
# Get testnet STT from faucet: https://faucet.somnia.network

# Deploy
somniactl deploy GameToken --network testnet
```

## Somnia-Specific Considerations

### High Throughput

Somnia targets 400,000+ TPS. Design contracts to:
- Minimize storage operations (most expensive)
- Use events for off-chain indexing
- Batch operations where possible

### Gaming Patterns

Common patterns for gaming/metaverse:
- ERC-721 for unique in-game items (NFTs)
- ERC-1155 for fungible/semi-fungible game assets
- Commit-reveal for fair randomness
- Meta-transactions for gasless UX

### Gas Optimization

```solidity
// Use calldata for read-only arrays
function processItems(uint256[] calldata items) external {
    // More gas efficient than memory
}

// Pack struct storage
struct Player {
    uint128 health;    // Pack into single slot
    uint128 mana;
}

// Use unchecked for safe math
unchecked {
    counter++;  // When overflow is impossible
}
```

## Common Tasks

### Check Wallet Balance

```bash
somniactl wallet balance
# or
cast balance $(somniactl wallet address) --rpc-url https://dream-rpc.somnia.network
```

### Interact with Deployed Contract

```bash
# Read state
cast call <contract-address> "balanceOf(address)" <wallet-address> \
    --rpc-url https://dream-rpc.somnia.network

# Write state (requires wallet)
cast send <contract-address> "mint(address,uint256)" <to> <amount> \
    --rpc-url https://dream-rpc.somnia.network \
    --private-key <key>
```

### Fork Testnet Locally

```bash
anvil --fork-url https://dream-rpc.somnia.network
```

## File Locations

| Path | Description |
|------|-------------|
| `~/.config/somniactl/` | CLI configuration and wallets |
| `~/.config/somniactl/wallets/` | Wallet keystore (plaintext JSON) |
| `~/.config/somniactl/config.json` | CLI settings |
| `/etc/chain/config.json` | Chain configuration (read-only) |

## Troubleshooting

### Transaction Failing

1. Check wallet has sufficient STT for gas
2. Verify contract is deployed: `cast code <address>`
3. Test locally first with Anvil

### RPC Issues

```bash
# Test RPC connectivity
cast block-number --rpc-url https://dream-rpc.somnia.network
```

### Compilation Errors

```bash
# Clean and rebuild
forge clean && forge build

# Check Solidity version compatibility
forge build --use 0.8.20
```

## Resources

- [Somnia Documentation](https://docs.somnia.network/)
- [Somnia Discord](https://discord.gg/somnia)
- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity Docs](https://docs.soliditylang.org/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
