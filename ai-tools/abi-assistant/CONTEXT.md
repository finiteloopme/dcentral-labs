# Project Context

This document maintains the complete context and planning decisions for the ABI Assistant MCP Server project. Update this file whenever significant architectural or implementation decisions are made.

## Usage with AI Tools

### Loading Context in OpenCode (Claude)
```bash
# Open the project directory
cd /path/to/abi-assistant

# OpenCode will automatically detect and read CONTEXT.md
# You can reference it directly in conversation:
# "Based on the CONTEXT.md file, let's implement Phase 2"
```

### Loading Context in Gemini CLI
```bash
# Method 1: Direct file reference
gemini chat --context CONTEXT.md "Help me implement the protocol discovery system"

# Method 2: Project mode
gemini project init --context-file CONTEXT.md
gemini chat "Let's work on the intent interpretation layer"

# Method 3: Include in config
# In examples/gemini-agent/config.yaml:
context_files:
  - ../../CONTEXT.md
```

### Best Practices
- Reference CONTEXT.md at the start of new sessions for continuity
- Update this file after significant changes
- Use section headers as reference points (e.g., "See Phase 3 in CONTEXT.md")

## Project Overview

**Purpose**: MCP (Model Context Protocol) server that enables AI agents to interact with EVM smart contracts through natural language intents.

**Core Value Proposition**: Bridge the gap between AI agents and blockchain by interpreting natural language intents into executable smart contract calls.

## Technology Stack

- **Backend**: Rust (chosen for performance, type safety, and memory safety critical for DeFi)
- **Database**: SQLite (ABI storage and caching)
- **Build System**: Make + Shell scripts (minimalistic, maintainable)
- **Containerization**: Podman for all builds and dependencies (no local installation required)
- **Protocol**: MCP (Model Context Protocol) via JSON-RPC
- **Blockchain Libraries**: `alloy` or `ethers-rs`

## Architecture Decisions

### 1. Intent Interpretation Layer

**Decision**: Implement a multi-level intent resolution system

**Rationale**: AI agents shouldn't need to know specific function names or contract addresses

**Implementation**:
- Natural language → Intent classification
- Intent → Protocol resolution
- Protocol → Specific function mapping
- Function → Encoded calldata

### 2. Three-Tier Architecture

```
┌─────────────────────────────────────┐
│        MCP Interface Layer          │  ← JSON-RPC tools exposed to agents
├─────────────────────────────────────┤
│     Intent Processing Layer         │  ← NLP and semantic understanding
├─────────────────────────────────────┤
│      Blockchain Layer              │  ← ABI encoding, RPC calls
└─────────────────────────────────────┘
```

### 3. Storage Strategy

- **SQLite**: Persistent storage for ABIs with metadata
- **In-memory LRU Cache**: Frequently used ABIs
- **Pre-loaded ABIs**: Common protocols (Uniswap, Aave, etc.)

### 4. Transaction Workflow

**Decision**: Support complete transaction lifecycle without handling private keys

**Rationale**: Enable agents to prepare transactions that users can sign with their preferred wallet

**Workflow**:
1. Intent → Transaction construction
2. Simulation & validation
3. Export in multiple formats
4. User signs with external wallet (MetaMask, Ledger, etc.)
5. Optional: Monitor transaction status

**Export Formats**:
- Raw transaction JSON (for web3 libraries)
- EIP-712 typed data (for smart wallets)
- QR code format (for mobile wallets)
- WalletConnect deep links

### 5. Dynamic Protocol Discovery

**Decision**: Support arbitrary DeFi protocols without hard-coding specific implementations

**Rationale**: Web3 evolves rapidly; new protocols launch daily, and hard-coding each would be unsustainable

**Implementation Strategy**:

1. **Protocol Pattern Recognition**
   - Identify protocol type by analyzing ABI signatures
   - Common patterns: AMM (swap functions), Lending (supply/borrow), Staking (stake/unstake)
   - Use heuristics and ML to classify unknown protocols

2. **Dynamic ABI Acquisition**
   - On-demand fetching from Etherscan/Blockscout
   - 4byte signature database integration
   - Direct contract bytecode analysis
   - Community-submitted ABI registry

3. **Standard Interface Detection**
   - ERC20, ERC721, ERC1155 for tokens
   - ERC4626 for vaults
   - Custom standards (Uniswap V2/V3 interfaces)

4. **Protocol Metadata System**
   ```json
   {
     "protocol": "NewDeFiProtocol",
     "type": "detected:amm",
     "confidence": 0.85,
     "patterns_matched": ["swap", "addLiquidity", "removeLiquidity"],
     "verified_source": "etherscan",
     "similar_to": ["Uniswap V2", "Sushiswap"]
   }
   ```

5. **Self-Learning Capabilities**
   - Track successful interactions
   - Build protocol knowledge base
   - Share learnings across agent network

**Protocol Discovery Flow**:

```rust
// Example: User wants to interact with new protocol
async fn handle_new_protocol(address: Address) -> Result<Protocol> {
    // Step 1: Check local registry
    if let Some(protocol) = registry.get(address) {
        return Ok(protocol);
    }
    
    // Step 2: Fetch ABI from multiple sources
    let abi = try_fetch_abi(address).await?;
    
    // Step 3: Analyze and classify
    let classification = classify_protocol(&abi)?;
    
    // Step 4: Generate interaction mappings
    let mappings = match classification.protocol_type {
        ProtocolType::AMM => generate_amm_mappings(&abi),
        ProtocolType::Lending => generate_lending_mappings(&abi),
        ProtocolType::Vault => generate_vault_mappings(&abi),
        _ => generate_generic_mappings(&abi),
    };
    
    // Step 5: Store in registry for future use
    registry.store(Protocol {
        address,
        abi,
        classification,
        mappings,
        confidence: classification.confidence,
    });
    
    Ok(protocol)
}
```

**Pattern Matching Example**:

```rust
// Detecting AMM protocols dynamically
fn detect_amm_protocol(abi: &Abi) -> Option<AmmType> {
    let functions: HashSet<_> = abi.functions.keys().collect();
    
    // Uniswap V2 pattern
    if functions.contains("swapExactTokensForTokens") &&
       functions.contains("addLiquidity") &&
       functions.contains("removeLiquidity") {
        return Some(AmmType::UniswapV2Like);
    }
    
    // Uniswap V3 pattern
    if functions.contains("exactInputSingle") &&
       functions.contains("mint") &&
       functions.contains("positions") {
        return Some(AmmType::UniswapV3Like);
    }
    
    // Curve pattern
    if functions.contains("exchange") &&
       functions.contains("add_liquidity") &&
       functions.contains("calc_token_amount") {
        return Some(AmmType::CurveLike);
    }
    
    // Generic AMM pattern
    if has_swap_functions(&functions) && has_liquidity_functions(&functions) {
        return Some(AmmType::Generic);
    }
    
    None
}
```

**Community Registry Format**:

```json
{
  "protocol_id": "new-defi-protocol-v1",
  "name": "NewDeFiProtocol",
  "addresses": {
    "ethereum": "0x...",
    "polygon": "0x...",
    "arbitrum": "0x..."
  },
  "abi_source": "verified_etherscan",
  "classification": {
    "type": "amm",
    "subtype": "concentrated_liquidity",
    "confidence": 0.95
  },
  "common_operations": {
    "swap": {
      "function": "swapWithPrice",
      "parameters": ["tokenIn", "tokenOut", "amount", "minOut"],
      "gas_estimate": 150000
    },
    "add_liquidity": {
      "function": "provideLiquidity",
      "parameters": ["token0", "token1", "amount0", "amount1"],
      "gas_estimate": 250000
    }
  },
  "verified_by": ["agent_001", "agent_002"],
  "usage_count": 1523,
  "success_rate": 0.98
}
```

### 6. Agent-to-Agent Protocol

**Decision**: Implement standardized agent communication for collaborative DeFi operations

**Rationale**: Enable multi-agent workflows, strategy sharing, and distributed decision-making

**Communication Types**:

1. **Strategy Sharing**
   - Share discovered arbitrage opportunities
   - Coordinate liquidity provision
   - Distribute market analysis

2. **Transaction Coordination**
   - Multi-signature transaction preparation
   - Sequential operation dependencies
   - Cross-chain bridging coordination

3. **Information Exchange**
   - Share validated ABIs
   - Exchange gas price predictions
   - Propagate protocol warnings/alerts

**Protocol Format**:
```json
{
  "version": "1.0",
  "type": "strategy|transaction|information|query",
  "sender": "agent_identifier",
  "recipient": "agent_identifier|broadcast",
  "payload": {
    "intent": "structured_intent",
    "confidence": 0.95,
    "context": {},
    "signature": "cryptographic_proof"
  }
}
```

**Security Considerations**:
- Agent identity verification via signatures
- Rate limiting to prevent spam
- Reputation scoring for agent reliability
- Encrypted channels for sensitive data

## Project Structure

```
abi-assistant/
├── Cargo.toml                 # Rust dependencies
├── Makefile                   # Build commands
├── README.md                  # User-facing documentation
├── CONTEXT.md                 # This file - project context
├── .env.example               # Environment configuration template
├── scripts/                   # Shell scripts for operations
│   ├── setup.sh              # Initial setup
│   ├── dev.sh                # Development server
│   ├── test.sh               # Test runner
│   ├── test-forked.sh        # Forked mainnet tests
│   ├── db-setup.sh           # Database initialization
│   ├── abi-fetch.sh          # Fetch protocol ABIs
│   ├── release.sh            # Release preparation
│   └── common.sh             # Shared utilities
├── src/                      # Rust source code
│   ├── main.rs               # Entry point
│   ├── server/               # MCP server implementation
│   ├── intent/               # Intent interpretation
│   │   ├── classifier.rs     # Intent classification
│   │   ├── resolver.rs       # Protocol resolution
│   │   └── patterns/         # Intent patterns by category
│   ├── abi/                  # ABI management
│   │   ├── parser.rs         # ABI parsing
│   │   ├── encoder.rs        # Call encoding
│   │   ├── decoder.rs        # Transaction decoding
│   │   └── fetcher.rs       # Dynamic ABI fetching
│   ├── protocol/             # Dynamic protocol handling
│   │   ├── discovery.rs      # Protocol discovery engine
│   │   ├── classifier.rs     # Protocol type classification
│   │   ├── patterns.rs       # Common protocol patterns
│   │   ├── standards.rs      # ERC standards detection
│   │   └── registry.rs       # Protocol knowledge base
│   ├── transaction/          # Transaction construction
│   │   ├── builder.rs        # Transaction builder
│   │   ├── formatter.rs      # Export formatters
│   │   ├── validator.rs      # Pre-signing validation
│   │   └── simulator.rs      # Transaction simulation
│   ├── agent/                # Agent-to-agent communication
│   │   ├── protocol.rs       # Communication protocol
│   │   ├── registry.rs       # Agent registry
│   │   ├── messaging.rs      # Message handling
│   │   ├── reputation.rs     # Agent reputation system
│   │   └── coordinator.rs    # Multi-agent coordination
│   ├── chain/               # Blockchain interaction
│   ├── storage/             # Database and caching
│   └── tools/               # MCP tool definitions
├── resources/               # Static resources
│   ├── abis/               # Pre-loaded contract ABIs
│   ├── protocols/          # Protocol configurations
│   └── intent_patterns/    # Intent pattern definitions
├── tests/                   # Test suites
│   ├── unit/               # Unit tests
│   ├── integration/        # Integration tests
│   └── property/           # Property-based tests
├── benches/                # Performance benchmarks
├── docs/                   # Additional documentation
└── examples/               # Example implementations
    ├── gemini-agent/       # Gemini CLI integration example
    │   ├── config.yaml     # Gemini CLI configuration
    │   ├── setup.sh        # Setup script for Gemini agent
    │   ├── prompts/        # Custom prompts for DeFi operations
    │   └── scripts/        # Helper scripts
    └── agent-examples/     # Other agent integration examples
```

## MCP Tools Specification

### Core Tools

1. **interpret_intent**
   - Input: Natural language description
   - Output: Ranked list of possible contract calls
   - Example: "swap 100 USDC for ETH" → Uniswap swap function

2. **find_best_path**
   - Input: DeFi action and constraints
   - Output: Optimal execution path across protocols

3. **encode_function_call**
   - Input: ABI, function name, parameters
   - Output: Encoded calldata

4. **decode_transaction**
   - Input: Transaction data and ABI
   - Output: Human-readable function call

5. **estimate_gas**
   - Input: Transaction parameters
   - Output: Gas estimation

### Protocol Discovery Tools

1. **discover_protocol**
   - Input: Contract address or protocol name
   - Output: Protocol type, ABI, common operations
   - Auto-fetches from multiple sources

2. **analyze_protocol**
   - Input: Contract address
   - Output: Protocol classification, similar protocols, risk assessment
   - Uses pattern matching and heuristics

3. **register_protocol**
   - Input: Protocol metadata and ABI
   - Output: Registration confirmation
   - Community contribution mechanism

4. **query_protocol_registry**
   - Input: Protocol characteristics (type, chain, TVL)
   - Output: Matching protocols with confidence scores
   - Leverages shared knowledge base

### Transaction Construction Tools

1. **build_transaction**
   - Input: Intent or explicit parameters
   - Output: Unsigned transaction ready for signing
   - Includes: nonce, gas price, gas limit, to, value, data

2. **prepare_batch_transaction**
   - Input: Multiple operations
   - Output: Multicall transaction or batch of transactions
   - Use case: Complex DeFi strategies

3. **export_for_signing**
   - Input: Built transaction
   - Output: Multiple formats (JSON, hex, EIP-712 typed data)
   - Compatible with: MetaMask, WalletConnect, hardware wallets

### Agent Communication Tools

1. **broadcast_strategy**
   - Input: Strategy details, target agents
   - Output: Broadcast confirmation
   - Use case: Share arbitrage opportunities or market insights

2. **coordinate_transaction**
   - Input: Multi-party transaction requirements
   - Output: Coordination status and signatures
   - Use case: Multi-sig operations, DAO proposals

3. **query_agent_network**
   - Input: Information request (ABI, gas prices, protocol status)
   - Output: Aggregated responses from agent network
   - Use case: Crowdsource information and validation

4. **register_agent**
   - Input: Agent capabilities and specializations
   - Output: Agent identifier and network credentials
   - Use case: Join agent network with specific expertise

5. **verify_agent_message**
   - Input: Agent message with signature
   - Output: Verification status and agent reputation
   - Use case: Validate inter-agent communications

### DeFi-Specific Tools

1. **check_allowance** - ERC20 approval checking
2. **calculate_slippage** - Slippage parameter calculation
3. **simulate_transaction** - Pre-execution simulation
4. **get_pool_info** - Liquidity pool information
5. **validate_transaction** - Check transaction validity before signing

## Intent Categories & Protocol Patterns

```yaml
# Intent categories mapped to function signatures
Swapping:
  keywords: [swap, exchange, trade, convert]
  common_signatures:
    - "swap(address,address,uint256)"
    - "swapExactTokensForTokens"
    - "swapTokensForExactTokens"
    - "exchange"
  detection_patterns:
    - Has swap/exchange functions
    - Emits Swap/Trade events
    - Contains price/rate getters
  
Lending:
  keywords: [lend, supply, deposit, earn]
  common_signatures:
    - "supply(address,uint256)"
    - "deposit(uint256)"
    - "mint(uint256)"
  detection_patterns:
    - Has supply/withdraw pairs
    - Tracks user balances
    - Calculates interest rates
  
Borrowing:
  keywords: [borrow, loan, leverage]
  common_signatures:
    - "borrow(address,uint256)"
    - "flashLoan"
  detection_patterns:
    - Requires collateral
    - Has liquidation functions
    - Tracks debt positions
  
Staking:
  keywords: [stake, delegate, lock]
  common_signatures:
    - "stake(uint256)"
    - "delegate(address)"
  detection_patterns:
    - Time-locked deposits
    - Reward distribution
    - Unstake/withdraw delays
  
Liquidity:
  keywords: [provide liquidity, LP, add to pool]
  common_signatures:
    - "addLiquidity"
    - "mint(address,uint256,uint256)"
  detection_patterns:
    - Dual token deposits
    - LP token minting
    - Fee collection mechanisms

# Protocol type detection rules
protocol_classification:
  amm:
    required: [swap functions, liquidity functions]
    optional: [factory pattern, pair creation]
  
  lending:
    required: [supply/borrow functions, interest model]
    optional: [liquidation, flash loans]
  
  vault:
    required: [ERC4626 interface or deposit/withdraw]
    optional: [strategy functions, harvest]
  
  staking:
    required: [stake/unstake, reward calculation]
    optional: [delegation, slashing]
```

## Development Standards

### Code Documentation
- Every public function must have doc comments
- Include examples in documentation
- Use `///` for function docs, `//!` for module docs

### Testing Requirements
- Minimum 80% code coverage
- Unit tests for all pure functions
- Integration tests for MCP tools
- Property-based tests for encoders/decoders
- Fuzzing for input parsing

### Testing Strategy
```
Unit Tests       → Test individual functions
Integration Tests → Test tool interactions
Property Tests   → Test invariants
Fuzz Tests      → Test robustness
Forked Tests    → Test against real protocols
```

## Implementation Phases

### Phase 1: Foundation ✅ Complete
- [x] Project structure design
- [x] Technology stack selection
- [x] Build system setup plan
- [x] Basic MCP server skeleton
- [x] ABI parsing implementation
- [x] SQLite schema and storage

### Phase 2: Intent Layer
- [ ] Intent classification system
- [ ] Pattern matching engine
- [ ] Protocol registry
- [ ] Intent resolution pipeline

### Phase 3: Core Tools
- [ ] implement `interpret_intent`
- [ ] implement `encode_function_call`
- [ ] implement `decode_transaction`
- [ ] implement `estimate_gas`
- [ ] implement `build_transaction`
- [ ] implement `export_for_signing`

### Phase 4: Dynamic Protocol Integration
- [ ] Protocol-agnostic ABI discovery system
- [ ] Auto-fetch ABIs from on-chain/Etherscan/4byte
- [ ] Protocol pattern recognition (AMM, lending, etc.)
- [ ] Dynamic function mapping based on standards (ERC20, ERC4626, etc.)
- [ ] Protocol registry with community contributions
- [ ] Self-learning protocol interactions

### Phase 5: Advanced Features
- [ ] Transaction simulation
- [ ] MEV protection
- [ ] Cross-chain support
- [ ] Auto-fetch ABIs from Etherscan
- [ ] Agent-to-agent communication protocol
- [ ] Multi-agent coordination system
- [ ] Agent reputation scoring

### Phase 6: Production Readiness
- [ ] Performance optimization
- [ ] Comprehensive testing
- [ ] Documentation completion
- [ ] Docker containerization

## Configuration

### Environment Variables
```bash
# RPC Endpoints
ETH_RPC_URL=             # Ethereum mainnet RPC
POLYGON_RPC_URL=         # Polygon RPC
ARBITRUM_RPC_URL=        # Arbitrum RPC

# API Keys
ETHERSCAN_API_KEY=       # For fetching ABIs
INFURA_API_KEY=          # Backup RPC provider

# Database
DATABASE_URL=sqlite://./data/abi_assistant.db

# Server
MCP_HOST=127.0.0.1
MCP_PORT=3000

# Logging
RUST_LOG=info            # debug, info, warn, error
```

## Key Design Principles

1. **Agent-First**: All tools designed for AI agent consumption
2. **Safety**: Never execute transactions without simulation
3. **Transparency**: Clear explanations of what will happen
4. **Flexibility**: Support multiple protocols for same intent
5. **Performance**: Sub-second response times for common operations
6. **Non-Custodial**: Never handle private keys, only prepare transactions for external signing
7. **Collaborative**: Enable secure agent-to-agent communication for complex strategies

## Dependencies

### Core Rust Crates
- `tokio`: Async runtime
- `alloy`/`ethers-rs`: Ethereum interaction
- `sqlx`: Database operations
- `serde`: Serialization
- `jsonrpc-core`: MCP protocol

### Development Dependencies
- `criterion`: Benchmarking
- `proptest`: Property testing
- `mockall`: Mocking framework
- `cargo-tarpaulin`: Coverage reporting

## Future Enhancements

### Planned Features
- [ ] Natural language explanations of transactions
- [ ] Historical transaction analysis
- [ ] Gas optimization recommendations
- [ ] Multi-step transaction batching
- [ ] Protocol governance participation

### Potential Integrations
- [ ] 4byte.directory for signature lookup
- [ ] DeFiLlama for TVL data
- [ ] Chainlink for price feeds
- [ ] Tenderly for simulations
- [ ] IPFS for distributed agent knowledge base
- [ ] The Graph for indexed blockchain data
- [ ] Agent marketplaces for strategy trading

## Maintenance Tasks

### Regular Updates Needed
- [ ] Weekly: Update protocol ABIs
- [ ] Monthly: Review and update intent patterns
- [ ] Quarterly: Update dependencies
- [ ] Ongoing: Add new protocol support

## Performance Targets

- Intent interpretation: < 100ms
- ABI encoding: < 10ms
- Transaction simulation: < 1s
- Database queries: < 50ms

## Security Considerations

1. **Input Validation**: All inputs sanitized and validated
2. **Address Verification**: Checksum validation for addresses
3. **Slippage Protection**: Default slippage limits
4. **Simulation First**: Always simulate before suggesting execution
5. **No Private Keys**: Never handle or store private keys

## Testing Checklist

Before any release:
- [ ] All tests passing
- [ ] Coverage > 80%
- [ ] No clippy warnings
- [ ] Documentation updated
- [ ] Benchmarks run and compared
- [ ] Forked mainnet tests passing

## Contribution Guidelines

1. Follow Rust naming conventions
2. Add tests for new features
3. Update documentation
4. Run `make check` before commits
5. Update CONTEXT.md for architectural changes

## Release Process

1. Run `make check` for all validations
2. Update version in `Cargo.toml`
3. Run `make release VERSION=x.y.z`
4. Create GitHub release with notes
5. Publish to crates.io if applicable

## Support Channels

- GitHub Issues: Bug reports and feature requests
- Documentation: `/docs` directory
- Examples: `/examples` directory

## License

MIT License - See LICENSE file for details

---

## Session History

### Session 1 (2024-10-22)
- Initial project planning
- Technology stack selection (Rust chosen over Go)
- Architecture design with intent interpretation layer
- Build system design with Make and shell scripts
- Documentation and testing standards established
- Created comprehensive project structure
- Added transaction construction and signing workflow (non-custodial approach)
- Designed agent-to-agent communication protocol for collaborative DeFi strategies
- Pivoted from hard-coded protocol support to dynamic protocol discovery system
- Added protocol pattern recognition for automatic classification
- Implemented Gemini CLI agent example with complete integration

### Session 2 (2024-10-22) - Current
- **Resolved Rust dependency issues** with `edition2024` requirement
  - Pinned dependencies to stable versions (Rust 1.79 compatible)
  - Used minimal dependencies initially (serde, serde_json, hex, sha3)
  - Fixed indexmap version to 2.0.0 to avoid Rust 1.82 requirement
- **Implemented Phase 1: Foundation** ✅
  - Created basic MCP server with JSON-RPC support
  - Implemented ABI parsing, encoding, and decoding modules
  - Set up SQLite database with schema for ABIs, protocols, and intents
  - Created server module with health check and MCP tools endpoints
  - Successfully compiled and ran the server on port 3000
- **Created initial MCP tools**:
  - `interpret_intent` - Convert natural language to contract calls
  - `encode_function_call` - Encode function calls with ABI
  - `decode_transaction` - Decode transaction data
  - `estimate_gas` - Gas estimation (placeholder)
- **Testing infrastructure**:
  - Created test-mcp.sh script for endpoint testing
  - All unit tests passing (4 tests for ABI modules)
  - Server successfully starts and listens on port 3000

### Current Status
- Basic MCP server is functional and accepting connections
- Database initialization working with proper schema
- Container-based development environment fully operational
- Ready to proceed with Phase 2: Intent Layer

### Next Steps
1. Fix health endpoint issue (connection reset)
2. Implement proper HTTP response handling
3. Build intent classification system (Phase 2)
4. Add more sophisticated intent patterns
5. Implement protocol discovery mechanisms
6. Create comprehensive integration tests

## Example Implementations

### Gemini CLI Agent Configuration

The project includes a complete example of integrating Gemini CLI with the ABI Assistant MCP server.

**Location**: `examples/gemini-agent/`

**Configuration** (`examples/gemini-agent/config.yaml`):
```yaml
name: defi-agent
model: gemini-pro
mcp_servers:
  - name: abi-assistant
    url: http://localhost:3000
    protocol: json-rpc
    capabilities:
      - intent_interpretation
      - transaction_building
      - abi_management

system_prompt: |
  You are a DeFi assistant that helps users interact with Ethereum smart contracts.
  You have access to the ABI Assistant MCP server for blockchain operations.
  
  Available tools:
  - interpret_intent: Convert natural language to contract calls
  - build_transaction: Create unsigned transactions
  - simulate_transaction: Test transactions before execution
  - export_for_signing: Generate signing formats for wallets
  
  Always:
  1. Simulate transactions before presenting them to users
  2. Explain risks and gas costs
  3. Never execute transactions directly - always export for user signing

context:
  default_chain: ethereum
  preferred_protocols:
    - Uniswap V3
    - Aave V3
  slippage_tolerance: 0.5%
  gas_mode: standard
```

**Setup Script** (`examples/gemini-agent/setup.sh`):
```bash
#!/usr/bin/env bash

# Install Gemini CLI
pip install gemini-cli

# Start ABI Assistant MCP server
cd ../..
make dev &

# Configure Gemini CLI with MCP
gemini config set mcp.enabled true
gemini config set mcp.server http://localhost:3000

# Test connection
gemini test-mcp abi-assistant

echo "Gemini agent ready for DeFi operations!"
```

**Usage Examples**:

```bash
# Simple swap
gemini chat "I want to swap 1000 USDC for ETH"
# Response: Prepares transaction, simulates, returns signing data

# Complex DeFi strategy
gemini chat "Find the best yield for my 10000 USDC for 6 months"
# Response: Analyzes lending protocols, prepares transactions

# Multi-step operation
gemini chat "Borrow DAI against my ETH, then stake it in Yearn"
# Response: Builds batch transaction for the entire flow
```

**Custom Prompts** (`examples/gemini-agent/prompts/`):
- `arbitrage.txt`: Prompt for finding arbitrage opportunities
- `yield-farming.txt`: Prompt for yield optimization
- `portfolio-rebalance.txt`: Prompt for portfolio management
- `gas-optimization.txt`: Prompt for gas-efficient execution

**Integration Features**:
1. **Automatic MCP discovery**: Gemini CLI auto-discovers available tools
2. **Context persistence**: Maintains transaction history and user preferences
3. **Safety checks**: Built-in simulation before any transaction
4. **Multi-wallet support**: Can prepare transactions for different wallets
5. **Agent collaboration**: Can communicate with other Gemini agents via the agent protocol

---

**Note**: This document should be updated whenever significant decisions or changes are made to maintain continuity across development sessions.