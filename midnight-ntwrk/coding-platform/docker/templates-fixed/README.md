# Midnight Token DApp Template

A basic token implementation for Midnight Network with privacy-preserving features.

## Quick Start

```bash
# Compile the contract
make compile

# Run tests
make test

# Generate zero-knowledge proofs
make prove

# Deploy to testnet
make deploy

# Start development server
make dev
```

## Project Structure

```
basic-token/
├── contracts/          # Compact smart contracts
│   └── Token.compact   # Token contract implementation
├── src/                # Application source code
│   └── index.js        # Express server and API
├── test/               # Test files
│   └── token.test.js   # Contract tests
├── build/              # Compiled contracts (generated)
├── proofs/             # Generated proofs (generated)
├── Makefile            # Build automation
├── package.json        # Node.js dependencies
└── README.md           # This file
```

## Contract Features

- **ERC20-like Interface**: Standard token operations (transfer, approve, etc.)
- **Privacy Features**: Zero-knowledge proof generation for transactions
- **Minting/Burning**: Token supply management
- **Access Control**: Owner-only functions for administration

## API Endpoints

The development server provides these endpoints:

- `GET /` - Web interface
- `GET /api/contract` - Get compiled contract data
- `POST /api/deploy` - Deploy contract to testnet
- `POST /api/transfer` - Transfer tokens
- `GET /api/balance/:address` - Check token balance

## Development

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Compile contracts**:
   ```bash
   make compile
   ```

3. **Start development server**:
   ```bash
   make dev
   ```

4. **Access the DApp**:
   Open http://localhost:3000 in your browser

## Testing

Run the test suite:
```bash
make test
```

## Deployment

Deploy to Midnight testnet:
```bash
make deploy
```

This will:
1. Compile the contract
2. Generate zero-knowledge proofs
3. Submit to the testnet
4. Return the contract address

## Environment Variables

- `MIDNIGHT_NETWORK` - Network to deploy to (default: testnet)
- `PROOF_SERVICE_URL` - URL of proof generation service
- `PORT` - Development server port (default: 3000)

## License

MIT