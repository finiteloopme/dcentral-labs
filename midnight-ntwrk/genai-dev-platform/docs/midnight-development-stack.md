# Midnight Development Stack Guide

This guide explains how to use the integrated Midnight Network development environment that runs in each workstation.

## Overview

The Midnight Development Stack provides a complete local development environment including:

- **Midnight Node** - Blockchain node for local development
- **Proof Server** - ZK proof generation service  
- **Indexer** - Data indexing and query service
- **PostgreSQL** - Database for indexer and applications

## Architecture

### Google Cloud Workstation

```
┌─────────────────────────────────────────────────────────────────────────┐
│                Google Cloud Workstation Container              │
│                                                         │
│  ┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐  │
│  │   Midnight Node │    │  Proof Server   │    │   Indexer       │  │
│  │   (Port 9944)  │    │  (Port 8081)   │    │  (Port 8088)   │  │
│  └─────────┬───────┘    └──────────────────┘    └─────────┬───────┘  │
│           │                                        │            │
│           └───────────────────────┬────────────────┘            │
│                              │                         │
│           ┌─────────────────┐    ┌─────────────────┐            │
│           │  PostgreSQL     │    │   Code OSS     │            │
│           │  (Port 5432)   │    │  (Port 80)     │            │
│           └─────────────────┘    └─────────────────┘            │
│                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```



## Quick Start

### In Google Cloud Workstation

The Midnight stack starts automatically when you access your workstation. All services run as background processes within the container:

```bash
# Check service status
midnight-dev status

# View logs
midnight-dev logs

# Restart services if needed
midnight-dev restart

# Access specific service logs
midnight-dev logs node        # Node logs
midnight-dev logs proof         # Proof server logs
midnight-dev logs indexer       # Indexer logs
midnight-dev logs all          # All logs
```

**Automatic Startup**: All services start automatically when the workstation boots, with health checks and proper initialization.



## Service Details

### Midnight Node

- **Purpose**: Blockchain node for local development
- **Port**: 9944 (HTTP/WebSocket)
- **Config**: Development preset with mock chain follower
- **Access**: http://localhost:9944
- **WebSocket**: ws://localhost:9944

**Usage Examples:**
```bash
# Check node status
curl http://localhost:9944/health

# Access via WebSocket
wscat -c ws://localhost:9944
```

### Proof Server

- **Purpose**: Zero-knowledge proof generation
- **Port**: 8081
- **Network**: Testnet configuration
- **Mode**: Local development
- **Access**: http://localhost:8081

**Usage Examples:**
```bash
# Generate proof
curl -X POST http://localhost:8081/generate \
  -H "Content-Type: application/json" \
  -d '{"input": "your_data"}'

# Check server status
curl http://localhost:8081/status
```

### Indexer

- **Purpose**: Blockchain data indexing and query API
- **Port**: 8088
- **Database**: PostgreSQL (indexer_db)
- **Network**: TestNet
- **Access**: http://localhost:8088

**Usage Examples:**
```bash
# Get indexed blocks
curl http://localhost:8088/blocks

# Query transactions
curl http://localhost:8088/transactions \
  -H "Content-Type: application/json" \
  -d '{"fromBlock": 0, "toBlock": 100}'

# Check indexer health
curl http://localhost:8088/health
```

### PostgreSQL

- **Purpose**: Database for indexer and development
- **Port**: 5432
- **User**: postgres / midnight
- **Databases**: midnight_dev, midnight_test, indexer_db

**Connection Examples:**
```bash
# Connect with psql
psql -h localhost -p 5432 -U postgres -d midnight_dev

# Connect with application credentials
psql -h localhost -p 5432 -U midnight -d midnight_dev

# From Node.js
const { Pool } = require('pg');
const pool = new Pool({
  host: 'localhost',
  port: 5432,
  user: 'midnight',
  password: 'midnight123',
  database: 'midnight_dev'
});
```

## Development Workflow

### 1. Smart Contract Development

```bash
# Start Midnight stack
make midnight-start

# Deploy contract locally
midnight-cli contract deploy --local --node http://localhost:9944

# Test contract
midnight-cli contract call --local --address <contract-address> --method <method>
```

### 2. DApp Development

```javascript
// Connect to local node
const nodeUrl = 'http://localhost:9944';
const indexerUrl = 'http://localhost:8088';

// Deploy and test DApp
const dapp = new MidnightDApp(nodeUrl, indexerUrl);
await dapp.deploy();
await dapp.test();
```

### 3. Testing with Proofs

```bash
# Generate ZK proof for transaction
curl -X POST http://localhost:8081/generate \
  -H "Content-Type: application/json" \
  -d '{
    "transaction": "your_tx_data",
    "witness": "witness_data"
  }'

# Verify proof
curl -X POST http://localhost:8081/verify \
  -H "Content-Type: application/json" \
  -d '{
    "proof": "generated_proof",
    "public_input": "public_data"
  }'
```

## Management Commands

### Service Status

```bash
# Show all services status
midnight-dev status

# Output:
# ✅ Midnight Node: RUNNING (port 9944)
# ✅ Proof Server: RUNNING (port 8081)  
# ✅ Indexer: RUNNING (port 8088)
# ✅ PostgreSQL: RUNNING (port 5432)
```

### Log Management

```bash
# View all logs
midnight-dev logs all

# Follow specific service logs
midnight-dev logs node        # Node logs
midnight-dev logs proof       # Proof server logs
midnight-dev logs indexer     # Indexer logs

# Real-time log monitoring
midnight-dev logs indexer | grep "ERROR"  # Filter errors
```

### Service Shell Access

```bash
# Access PostgreSQL shell
midnight-dev shell postgres
psql -U postgres -d midnight_dev

# Access Node shell
midnight-dev shell midnight-node
# Inside container: /usr/local/bin/midnight-node --help

# Access Proof Server shell  
midnight-dev shell proof-server
# Inside container: /usr/local/bin/midnight-proof-server --help

# Access Indexer shell
midnight-dev shell indexer
# Inside container: /usr/local/bin/midnight-indexer-standalone --help
```

## Troubleshooting

### Common Issues

**Port Conflicts:**
```bash
# Check if ports are in use
netstat -tulpn | grep -E ':(9944|8081|8088|5432)'

# Kill conflicting processes
sudo fuser -k 9944/tcp  # Node
sudo fuser -k 8081/tcp  # Proof Server
sudo fuser -k 8088/tcp  # Indexer
sudo fuser -k 5432/tcp  # PostgreSQL
```

**Service Not Starting:**
```bash
# Check service logs
midnight-dev logs

# Restart specific service
midnight-dev restart

# Reset entire environment (caution: destroys data)
midnight-dev reset
```

**Database Issues:**
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Restart PostgreSQL
sudo systemctl restart postgresql

# Check connection
psql -h localhost -p 5432 -U postgres -c "SELECT 1;"
```

### Performance Tuning

**Indexer Performance:**
```yaml
# In indexer-config.yaml
chain_indexer_application:
  blocks_buffer: 50        # Increase for better performance
  save_zswap_state_after: 500  # More frequent saves

infra:
  storage:
    cnn_url: "/data/indexer.sqlite"  # Use SSD for better performance
```

**Node Performance:**
```bash
# Add more memory to Node
export RUST_LOG=info  # Reduce log verbosity
/usr/local/bin/midnight-node --dev --rpc-external --ws-external
```

## Integration with IDE

### VS Code Extensions

Install Midnight Network extensions for better development experience:

1. **Midnight Compact** - Syntax highlighting and IntelliSense
2. **PostgreSQL** - Database management
3. **REST Client** - API testing with Indexer

### Environment Variables

The workstation configures these automatically:

```bash
GOOGLE_VERTEX_PROJECT=kunal-scratch
GOOGLE_VERTEX_LOCATION=us-central1
MIDNIGHT_ENV=dev
MIDNIGHT_NETWORK=testnet
CLOUD_WORKSTATIONS_CONFIG=true
```

## Next Steps

1. **Deploy to TestNet**: Use `make deploy` to deploy to cloud
2. **Contract Testing**: Test contracts locally before mainnet deployment
3. **DApp Development**: Build full-stack applications with local stack
4. **Integration Testing**: Use indexer for data-driven testing

## Support

- **Documentation**: [Midnight Network Docs](https://docs.midnight.network)
- **Examples**: [GitHub Examples](https://github.com/midnightntwrk/examples)
- **Community**: [Discord Community](https://discord.gg/midnight)