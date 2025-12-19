# Integration Tests

Integration tests for the Midnight CLI that run against live Midnight services.

## Prerequisites

1. **Midnight services running:**
   - Node (WebSocket RPC)
   - Indexer (GraphQL API)
   - Proof Server (gRPC)

2. **Toolkit binary installed:**
   ```bash
   # Option 1: Extract from Docker image
   docker pull midnightntwrk/midnight-node-toolkit:0.18.0
   docker run --rm -v /usr/local/bin:/out midnightntwrk/midnight-node-toolkit:0.18.0 \
     cp /usr/bin/midnight-node-toolkit /out/

   # Option 2: Set custom path
   export MIDNIGHT_TOOLKIT_PATH=/path/to/midnight-node-toolkit
   ```

3. **CLI built:**
   ```bash
   cd cli
   npm install
   npm run build
   ```

## Configuration

Create or update `.env` file in the **project root directory** (not in cli/):

```bash
# Midnight Node WebSocket URL
MIDNIGHT_NODE_URL=ws://your-node:9944

# Indexer GraphQL URL (path will be auto-appended if missing)
INDEXER_URL=http://your-indexer:8088

# Proof Server gRPC URL
PROOF_SERVER_URL=http://your-proof-server:6300

# Optional: Custom toolkit binary path
# MIDNIGHT_TOOLKIT_PATH=/usr/local/bin/midnight-node-toolkit
```

### GKE Cluster Example

If running against a GKE cluster with LoadBalancer services:

```bash
# Get service IPs
kubectl -n midnight-services get svc

# Update .env with external IPs
MIDNIGHT_NODE_URL=ws://34.x.x.x:9944
INDEXER_URL=http://34.x.x.x:8088
PROOF_SERVER_URL=http://34.x.x.x:6300
```

## Running Tests

### From CLI directory

```bash
cd cli
npm run test:integration
```

### From project root (via Makefile)

```bash
make test-integration
```

## Test Structure

```
tests/integration/
├── setup.ts         # Environment loading, service availability checks
├── helpers.ts       # Test utilities (wallet creation, cleanup, etc.)
├── wallet.test.ts   # Wallet operation tests
└── README.md        # This file
```

## Test Wallet Naming

- All test wallets are prefixed with `_test_`
- Example: `_test_wallet_abc123_xyz`
- Wallets are automatically cleaned up after each test run

## Test Cases

### wallet create
- Creates wallet with correct address format (`mn_addr_undeployed1...`)
- Creates wallets with unique addresses
- Fails when creating duplicate wallet names

### wallet balance
- Shows zero balance for new unfunded wallet

### wallet fund
- Funds wallet from genesis successfully
- Balance matches expected amount after funding

### wallet send
- Transfers tokens between wallets (pending full implementation)

### address derivation
- Derived address matches toolkit output

## Timeouts

- Individual test timeout: 2 minutes
- Setup/teardown timeout: 1 minute
- Funding operations may take 30-60 seconds

## Troubleshooting

### "Services not available" message

The tests will skip if services are unreachable. Check:

1. Service URLs in `.env` are correct
2. Services are running and healthy:
   ```bash
   # Node health
   curl http://NODE_IP:9944/health

   # Indexer GraphQL
   curl http://INDEXER_IP:8088/api/v3/graphql \
     -H "Content-Type: application/json" \
     -d '{"query": "{ block { height } }"}'
   ```

### "Toolkit binary not found" error

Ensure the toolkit is installed and executable:

```bash
# Check default path
ls -la /usr/local/bin/midnight-node-toolkit

# Or set custom path
export MIDNIGHT_TOOLKIT_PATH=/path/to/toolkit
```

### Tests hang on funding

Transaction processing can take 30-60 seconds. If tests consistently hang:

1. Check proof server is running and has downloaded key material
2. Verify node is producing blocks:
   ```bash
   kubectl logs deployment/midnight-node -n midnight-services --tail=5
   ```

### Cleanup failures

If test wallets aren't cleaned up properly, remove them manually:

```bash
# List wallets
midnightctl wallet list

# Remove test wallets
midnightctl wallet remove _test_wallet_xxx --force
```
