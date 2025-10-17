# Proof Service Configuration Guide

## Overview

The Midnight Development Platform includes integrated proof generation capabilities with an API-compatible proof server that matches the Midnight proof server v4.0.0 interface. The platform supports two modes of operation:

1. **Local Mode** (Default) - Runs the proof server inside the workstation container
2. **External Mode** - Connects to an external proof service

## Configuration Modes

### Local Mode (Default)

In local mode, an API-compatible proof server runs within the workstation container, providing:
- Zero network latency for proof generation
- No external dependencies
- Full offline capability after initial setup
- Automatic service management

#### Configuration

```bash
# .env file
PROOF_SERVICE_MODE=local
PROOF_SERVICE_PORT=8080
PROOF_SERVICE_HOST=0.0.0.0
PROOF_SERVICE_LOG_LEVEL=info
PROOF_SERVICE_THREADS=4
PROOF_SERVICE_CACHE_SIZE=1000
```

#### Features
- **Automatic startup**: Proof server starts automatically when container launches
- **Health monitoring**: Service health is checked before accepting requests
- **Full API compatibility**: Implements the Midnight proof server v4.0.0 API
- **Resource optimization**: Configurable threads and cache for performance tuning
- **Enhanced mock service**: Provides realistic proof generation for development

### External Mode

Use external mode to connect to a dedicated proof service, such as:
- Shared team proof server
- High-performance proof cluster
- Midnight's official proof API

#### Configuration

```bash
# .env file
PROOF_SERVICE_MODE=external
PROOF_SERVICE_URL=https://proof-api.midnight.network
# Or your custom proof service
PROOF_SERVICE_URL=https://your-proof-service.com/api
```

#### Benefits
- Centralized proof generation
- Better resource utilization for teams
- Access to specialized hardware (GPUs, high-memory systems)
- Shared proof caching

## Docker Configuration

### Using Docker Compose

```yaml
# docker-compose.yml
services:
  workstation:
    image: midnight-workstation:latest
    environment:
      PROOF_SERVICE_MODE: ${PROOF_SERVICE_MODE:-local}
      PROOF_SERVICE_URL: ${PROOF_SERVICE_URL:-}
      PROOF_SERVICE_PORT: ${PROOF_SERVICE_PORT:-8080}
      # Additional configuration...
```

### Using Docker Run

```bash
# Local mode (default)
docker run -d \
  -p 8080:8080 \
  -e PROOF_SERVICE_MODE=local \
  midnight-workstation:latest

# External mode
docker run -d \
  -e PROOF_SERVICE_MODE=external \
  -e PROOF_SERVICE_URL=https://proof-api.midnight.network \
  midnight-workstation:latest
```

## Terraform Configuration

For Google Cloud Workstations deployment:

```hcl
# terraform.tfvars
proof_service_config = {
  mode         = "local"  # or "external"
  external_url = ""       # Set if mode is "external"
  port         = 8080
  host         = "0.0.0.0"
  log_level    = "info"
  threads      = 4
  cache_size   = 1000
  api_key      = ""       # If external service requires authentication
}
```

## Service Endpoints

The proof service exposes the following endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check endpoint |
| `/proof/generate` | POST | Generate a zero-knowledge proof |
| `/proof/verify` | POST | Verify a proof |
| `/circuits` | GET | List available circuits |
| `/metrics` | GET | Service metrics (Prometheus format) |

## Command Line Usage

### Generate Proof

```bash
# Using the prove command
prove input.json

# With specific circuit
prove --circuit proveBalance input.json

# With custom output
prove -o my-proof.json input.json
```

### Verify Proof

```bash
# Using the verify command
verify proof.json

# Verify and show details
verify --verbose proof.json
```

### Using Midnight CLI

```bash
# Compile and generate proofs
midnight compile
midnight prove

# Verify all proofs in build directory
midnight verify build/*.proof
```

## Performance Tuning

### Local Mode Optimization

```bash
# High-performance configuration
PROOF_SERVICE_THREADS=8      # Use more CPU cores
PROOF_SERVICE_CACHE_SIZE=5000  # Larger cache for repeated proofs
PROOF_SERVICE_LOG_LEVEL=warn   # Reduce logging overhead
```

### Resource Requirements

| Mode | CPU | Memory | Disk | Network |
|------|-----|--------|------|---------|
| Local (Basic) | 2 cores | 4 GB | 10 GB | None |
| Local (Optimal) | 4 cores | 8 GB | 20 GB | None |
| External | 1 core | 2 GB | 5 GB | Required |

## Monitoring and Debugging

### Check Service Status

```bash
# Inside container
curl http://localhost:8080/health

# From host (if port exposed)
curl http://localhost:8080/health
```

### View Logs

```bash
# Local mode logs
docker exec midnight-workstation tail -f /var/log/midnight/proof-server.log

# Check startup logs
docker logs midnight-workstation | grep -i proof
```

### Common Issues

#### Service Won't Start

1. Check available memory:
```bash
docker exec midnight-workstation free -h
```

2. Verify binary exists:
```bash
docker exec midnight-workstation ls -la /opt/midnight/bin/proof-server
```

3. Check port availability:
```bash
docker exec midnight-workstation netstat -tulpn | grep 8080
```

#### Slow Proof Generation

1. Increase thread count:
```bash
PROOF_SERVICE_THREADS=8
```

2. Enable circuit preloading:
```bash
docker exec midnight-workstation \
  echo "circuits.preload: true" >> /opt/midnight/config/proof-server.yaml
```

3. Monitor resource usage:
```bash
docker stats midnight-workstation
```

## Migration Guide

### From Mock to Real Proof Server

1. Update your `.env` file:
```bash
# Before (mock)
# No configuration needed, mock was default

# After (real proof server)
PROOF_SERVICE_MODE=local
PROOF_SERVICE_THREADS=4
```

2. Rebuild and restart:
```bash
docker-compose down
docker-compose build
docker-compose up -d
```

### From Local to External

1. Set up external service URL:
```bash
PROOF_SERVICE_MODE=external
PROOF_SERVICE_URL=https://your-proof-service.com
```

2. Test connectivity:
```bash
curl -I https://your-proof-service.com/health
```

3. Restart container:
```bash
docker-compose restart
```

## Security Considerations

### Local Mode
- Proof server runs with container privileges
- No network exposure by default
- Circuits stored locally in container

### External Mode
- Use HTTPS for external services
- Implement API key authentication if available
- Consider VPN/private networking for sensitive proofs
- Monitor external service usage and costs

## API Examples

### Generate Proof (Local or External)

```javascript
// Node.js example
const axios = require('axios');

const proofServiceUrl = process.env.PROOF_SERVICE_URL || 'http://localhost:8080';

async function generateProof(circuit, inputs) {
    const response = await axios.post(`${proofServiceUrl}/proof/generate`, {
        circuit: circuit,
        inputs: inputs,
        protocol: 'groth16'
    });
    return response.data;
}

// Usage
const proof = await generateProof('proveBalance', {
    balance: 1000,
    account: '0x123...'
});
```

### Verify Proof

```javascript
async function verifyProof(proof, publicSignals) {
    const response = await axios.post(`${proofServiceUrl}/proof/verify`, {
        proof: proof,
        publicSignals: publicSignals
    });
    return response.data.valid;
}

// Usage
const isValid = await verifyProof(proof, ['1000', '0x123...']);
console.log('Proof is valid:', isValid);
```

## Benchmarks

Typical proof generation times (local mode, 4 cores):

| Circuit Type | Input Size | Generation Time | Verification Time |
|--------------|------------|-----------------|-------------------|
| Simple Balance | 1 KB | ~500ms | ~50ms |
| Transfer | 2 KB | ~800ms | ~60ms |
| Batch (10 items) | 10 KB | ~2s | ~100ms |
| Complex State | 50 KB | ~5s | ~150ms |

## Additional Resources

- [Midnight Proof Server Documentation](https://docs.midnight.network/proof-server)
- [Circuit Development Guide](./COMPACT_DEVELOPMENT.md)
- [Performance Optimization Tips](https://docs.midnight.network/optimization)
- [Troubleshooting Guide](https://docs.midnight.network/troubleshooting)