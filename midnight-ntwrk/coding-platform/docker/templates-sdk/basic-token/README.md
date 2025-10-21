# Midnight Token DApp Template (SDK Version)

A complete token implementation for Midnight Network with full SDK integration and zero-knowledge proof support.

## Prerequisites

- Node.js v22.15.0 or higher
- Docker (for running the proof server)
- Midnight wallet seed (for deployment)

## Quick Start

```bash
# 1. Install dependencies
npm install

# 2. Start the proof server (required for ZK proofs)
npm run proof-server

# 3. Copy and configure environment
cp .env.example .env
# Edit .env and add your wallet seed

# 4. Compile the contract
npm run compile

# 5. Start development server
npm run dev
```

## Project Structure

```
basic-token/
├── contracts/              # Compact smart contracts
│   └── Token.compact       # Token contract implementation
├── src/                    # Application source code
│   ├── index.js           # Express server and API
│   ├── midnight-sdk.js    # Midnight SDK integration
│   └── logger.js          # Logging utilities
├── test/                   # Test files
│   └── token.test.js      # Contract tests
├── proof-server.yml        # Docker compose for proof server
├── package.json           # Node.js dependencies
├── .env.example           # Environment configuration template
└── README.md              # This file
```

## Midnight SDK Integration

This template includes full Midnight SDK integration with:

- **Proof Server**: Official `midnightnetwork/proof-server:4.0.0` for zero-knowledge proof generation
- **SDK Providers**: Complete provider setup for testnet/mainnet
- **Wallet Integration**: Full wallet support with seed-based authentication
- **Contract Deployment**: Automated deployment with ZK proofs
- **State Management**: Public and private state providers

## Key Features

### 1. Zero-Knowledge Proof Generation
All contract interactions automatically generate ZK proofs through the proof server:
```javascript
import { httpClientProofProvider } from '@midnight-ntwrk/midnight-js-http-client-proof-provider';

const proofProvider = httpClientProofProvider('http://localhost:6300');
```

### 2. Contract Deployment
Deploy contracts with automatic proof generation:
```javascript
const deployedContract = await deployTokenContract(
    contract,
    providers,
    walletProvider,
    'MyToken',
    'MTK',
    1000000
);
```

### 3. Private State Management
Secure private state storage using LevelDB:
```javascript
const privateStateProvider = levelPrivateStateProvider({
    privateStateStoreName: 'token-private-state'
});
```

## Proof Server Management

### In Containerized Environment (Cloud Workstation/Local Container)

The proof server runs automatically inside the container on port 8081.

#### Check Proof Server Status
```bash
/docker/scripts/proof-status.sh
```

#### Start Proof Server (if not running)
```bash
/docker/scripts/start-proof-server.sh
```

#### View Proof Server Logs
```bash
tail -f /tmp/proof-server.log
```

### For Standalone Development (Outside Container)

If running outside the container, you can use Docker:

```bash
# Start proof server with Docker
docker run -d -p 6300:6300 midnightnetwork/proof-server:4.0.0 \
  midnight-proof-server --network testnet

# Or use docker-compose
docker compose -f proof-server.yml up -d
```

## Environment Configuration

Create a `.env` file from the example:
```bash
cp .env.example .env
```

Configure the following:
```env
# Network Configuration
MIDNIGHT_NETWORK=testnet

# Testnet Endpoints (default values work)
MIDNIGHT_INDEXER=https://indexer.testnet-02.midnight.network/api/v1/graphql
MIDNIGHT_INDEXER_WS=wss://indexer.testnet-02.midnight.network/api/v1/graphql/ws
MIDNIGHT_NODE=https://rpc.testnet-02.midnight.network

# Proof Server (must be running locally)
PROOF_SERVER_URL=http://localhost:6300

# Wallet Seed (64 character hex string)
WALLET_SEED=your_wallet_seed_here

# Server Port
PORT=3000
```

## API Endpoints

The development server provides these endpoints:

- `GET /` - Web interface
- `GET /api/contract` - Get compiled contract data
- `POST /api/deploy` - Deploy contract with ZK proofs
- `POST /api/transfer` - Transfer tokens with privacy
- `GET /api/balance/:address` - Check token balance
- `GET /api/proof-status` - Check proof server connection

## Development Workflow

### 1. Initial Setup
```bash
# Install all dependencies
npm install

# Start the proof server (keep running)
npm run proof-server

# Configure environment
cp .env.example .env
# Add your wallet seed to .env
```

### 2. Contract Development
```bash
# Edit contracts/Token.compact

# Compile the contract
npm run compile

# Test the contract
npm test
```

### 3. Running the DApp
```bash
# Start development server
npm run dev

# Access the DApp
open http://localhost:3000
```

### 4. Deployment to Testnet

1. **Get testnet funds**: Visit [Midnight Testnet Faucet](https://midnight.network/test-faucet)
2. **Configure wallet seed**: Add your seed to `.env`
3. **Deploy contract**:
   ```bash
   npm run deploy
   ```

## Testing

Run the test suite:
```bash
npm test
```

## Troubleshooting

### Proof Server Issues

**Problem**: "Proof server not available"
```bash
# Check if Docker is running
docker --version

# Start the proof server
npm run proof-server

# Verify it's running
curl http://localhost:6300/health
```

**Problem**: Port 6300 already in use
```bash
# Stop existing proof server
docker compose -f proof-server.yml down

# Or use a different port in .env
PROOF_SERVER_URL=http://localhost:6301
```

### Compilation Issues

**Problem**: "Contract compilation failed"
```bash
# Ensure you have the compiler
npm install @midnight-ntwrk/compact-compiler

# Check contract syntax
compactc contracts/Token.compact --check
```

### Network Issues

**Problem**: "Cannot connect to testnet"
```bash
# Check network configuration in .env
MIDNIGHT_NETWORK=testnet

# Verify endpoints are accessible
curl https://rpc.testnet-02.midnight.network
```

## SDK Resources

- [Midnight Documentation](https://docs.midnight.network)
- [Compact Language Guide](https://docs.midnight.network/develop/reference/compact/writing)
- [SDK Reference](https://docs.midnight.network/develop/reference/sdk)
- [Example DApps](https://github.com/midnightntwrk)

## Security Notes

- **Never commit `.env` with real wallet seeds**
- **Generate new seeds for production**
- **Keep proof server behind firewall in production**
- **Use environment variables for sensitive data**

## License

MIT