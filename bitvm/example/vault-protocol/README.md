# BitVM3 TypeScript Frontend & SDK

TypeScript implementation for BitVM3 frontend, CLI tools, and developer SDK.

## 📁 Structure

```
typescript/
├── src/
│   ├── core/           # Core protocol types and logic
│   ├── crypto/         # Cryptographic utilities
│   ├── vault/          # Vault interaction logic
│   ├── challenge/      # Challenge system
│   ├── cli/           # CLI application
│   ├── sdk/           # Developer SDK
│   └── web/           # React web interface
├── package.json
└── tsconfig.json
```

## 🚀 Quick Start

### Installation
```bash
npm install
```

### Build
```bash
npm run build
```

### Run CLI
```bash
npm start
# or
npm run cli
```

### Run Web Interface
```bash
npm run web
```

### Run Tests
```bash
npm test
```

## 🔗 Connecting to Rust Backend

The TypeScript frontend connects to the Rust backend via REST API:

```typescript
import { BitVM3Client } from './sdk/client';

const client = new BitVM3Client({
  endpoint: 'http://localhost:3000',
  apiKey: 'your-api-key'
});

// Deposit BTC
await client.deposit({
  participant: 'alice',
  amount: 100000000, // 1 BTC in satoshis
  currency: 'BTC'
});

// Get vault state
const state = await client.getVaultState();
console.log('Total BTC:', state.totalBtc);
```

## 🎨 Web Interface

The web interface provides:
- Real-time vault statistics
- Deposit/withdrawal forms
- Lending position management
- Challenge monitoring
- Transaction history

## 🛠️ CLI Tools

Interactive CLI for:
- Managing deposits and withdrawals
- Creating lending positions
- Initiating challenges
- Monitoring vault state

## 📦 SDK Features

- Type-safe API client
- WebSocket subscriptions
- Transaction builders
- Cryptographic utilities
- Error handling

## 🧪 Testing

```bash
# Unit tests
npm test

# Integration tests (requires backend)
npm run test:integration

# E2E tests
npm run test:e2e
```

## 📚 Documentation

- [API Reference](./docs/api.md)
- [SDK Guide](./docs/sdk.md)
- [CLI Manual](./docs/cli.md)