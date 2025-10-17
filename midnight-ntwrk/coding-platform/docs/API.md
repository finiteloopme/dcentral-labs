# Proof Service API Documentation

## Overview

The Midnight Development Platform integrates with a proof generation service that can be either:
- **Local Mock Service** - Runs automatically for development
- **External Production Service** - Configured via `PROOF_SERVICE_URL`

The platform's CLI tools (`prove` and `verify`) automatically use the configured service.

## Base URL
```
# Local (default)
http://localhost:8080

# External (configured)
${PROOF_SERVICE_URL}
```

## Authentication
No authentication required for MVP. Production will use API keys.

## Endpoints

### Health Check

#### GET /health
Check service health status.

**Response:**
```json
{
  "status": "healthy",
  "service": "midnight-proof-service",
  "version": "0.1.0-mvp",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Service Information

#### GET /api/info
Get service capabilities and configuration.

**Response:**
```json
{
  "name": "Midnight Proof Service",
  "version": "0.1.0-mvp",
  "capabilities": [
    "proof-generation",
    "proof-verification",
    "circuit-compilation"
  ],
  "supportedProtocols": ["groth16", "plonk", "stark"],
  "endpoints": {
    "health": "/health",
    "info": "/api/info",
    "generate": "/api/proof/generate",
    "verify": "/api/proof/verify",
    "compile": "/api/circuit/compile"
  }
}
```

### Proof Generation

#### POST /api/proof/generate
Generate a zero-knowledge proof for a contract.

**Request Body:**
```json
{
  "contract": "Token",
  "inputs": {
    "publicSignals": ["0x123..."],
    "privateInputs": {
      "amount": 100,
      "recipient": "0xabc..."
    }
  },
  "protocol": "groth16"
}
```

**Parameters:**
- `contract` (string, required): Contract name
- `inputs` (object, optional): Public and private inputs
- `protocol` (string, optional): Proof protocol (default: "groth16")

**Response:**
```json
{
  "success": true,
  "proof": {
    "pi_a": ["0x1234...", "0x5678..."],
    "pi_b": [["0xabcd...", "0xef01..."], ["0x2345...", "0x6789..."]],
    "pi_c": ["0xbcde...", "0xf012..."],
    "protocol": "groth16"
  },
  "publicSignals": ["0x123..."],
  "verificationKey": "0xvkey...",
  "metadata": {
    "contract": "Token",
    "protocol": "groth16",
    "timestamp": "2024-01-15T10:30:00Z",
    "prover": "midnight-prover-0.1.0",
    "gasEstimate": 75000
  }
}
```

**Status Codes:**
- `200`: Proof generated successfully
- `400`: Invalid request parameters
- `500`: Internal server error

### Proof Verification

#### POST /api/proof/verify
Verify a zero-knowledge proof.

**Request Body:**
```json
{
  "proof": {
    "pi_a": ["0x1234...", "0x5678..."],
    "pi_b": [["0xabcd...", "0xef01..."], ["0x2345...", "0x6789..."]],
    "pi_c": ["0xbcde...", "0xf012..."],
    "protocol": "groth16"
  },
  "publicSignals": ["0x123..."],
  "verificationKey": "0xvkey..."
}
```

**Parameters:**
- `proof` (object, required): Proof data
- `publicSignals` (array, required): Public signals
- `verificationKey` (string, required): Verification key

**Response:**
```json
{
  "success": true,
  "valid": true,
  "metadata": {
    "verifier": "midnight-verifier-0.1.0",
    "timestamp": "2024-01-15T10:30:00Z",
    "gasUsed": 35000
  }
}
```

**Status Codes:**
- `200`: Verification completed
- `400`: Invalid proof format
- `500`: Internal server error

### Circuit Compilation

#### POST /api/circuit/compile
Compile a circuit from source code.

**Request Body:**
```json
{
  "source": "contract Token { ... }",
  "optimization": true
}
```

**Parameters:**
- `source` (string, required): Circuit source code
- `optimization` (boolean, optional): Enable optimization (default: true)

**Response:**
```json
{
  "success": true,
  "circuit": {
    "constraints": 5432,
    "publicInputs": 3,
    "privateInputs": 12,
    "outputs": 2,
    "r1cs": "0xr1cs...",
    "wasm": "0xwasm..."
  },
  "metadata": {
    "compiler": "midnight-compiler-0.1.0",
    "optimization": true,
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

**Status Codes:**
- `200`: Compilation successful
- `400`: Syntax error in source
- `500`: Compilation failed

### Supported Curves

#### GET /api/curves
Get list of supported elliptic curves.

**Response:**
```json
{
  "curves": [
    {
      "name": "bn128",
      "description": "Barreto-Naehrig curve",
      "security": 128
    },
    {
      "name": "bls12-381",
      "description": "BLS12-381 curve",
      "security": 128
    },
    {
      "name": "grumpkin",
      "description": "Grumpkin curve",
      "security": 128
    }
  ]
}
```

## Error Responses

All endpoints may return error responses in the following format:

```json
{
  "success": false,
  "error": "Error message description"
}
```

Common error codes:
- `400`: Bad Request - Invalid parameters
- `404`: Not Found - Endpoint doesn't exist
- `500`: Internal Server Error - Server-side error

## Rate Limiting

MVP has basic rate limiting:
- 100 requests per 15 minutes per IP
- Headers returned:
  - `X-RateLimit-Limit`: Request limit
  - `X-RateLimit-Remaining`: Remaining requests
  - `X-RateLimit-Reset`: Reset timestamp

## WebSocket Support (Future)

Future versions will support WebSocket connections for:
- Real-time proof generation progress
- Live verification results
- Circuit compilation updates

## SDK Examples

### JavaScript/TypeScript
```javascript
const proofService = require('@midnight/proof-service-sdk');

// Initialize client
const client = new proofService.Client({
  baseURL: 'http://localhost:8080'
});

// Generate proof
const proof = await client.generateProof({
  contract: 'Token',
  inputs: { amount: 100 },
  protocol: 'groth16'
});

// Verify proof
const result = await client.verifyProof(proof);
console.log('Proof valid:', result.valid);
```

### Python
```python
from midnight_proof_service import Client

# Initialize client
client = Client(base_url='http://localhost:8080')

# Generate proof
proof = client.generate_proof(
    contract='Token',
    inputs={'amount': 100},
    protocol='groth16'
)

# Verify proof
result = client.verify_proof(proof)
print(f"Proof valid: {result['valid']}")
```

### cURL
```bash
# Generate proof
curl -X POST http://localhost:8080/api/proof/generate \
  -H "Content-Type: application/json" \
  -d '{"contract":"Token","inputs":{},"protocol":"groth16"}'

# Verify proof
curl -X POST http://localhost:8080/api/proof/verify \
  -H "Content-Type: application/json" \
  -d @proof.json
```

## Testing

Use the provided test endpoints for development:

```bash
# Test proof generation
curl http://localhost:8080/api/proof/generate \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"contract":"TestContract"}'

# Test health check
curl http://localhost:8080/health
```

## Troubleshooting

### Common Issues

1. **Connection Refused**
   - Ensure service is running: `ps aux | grep proof-service`
   - Check port availability: `netstat -an | grep 8080`

2. **Timeout Errors**
   - Default timeout is 30 seconds
   - Large circuits may need increased timeout

3. **Invalid Proof Format**
   - Ensure all proof components are present
   - Check protocol compatibility

## CLI Integration

The Midnight CLI tools automatically use the configured proof service:

### Using the prove command
```bash
# Generate proof for a single file
prove build/Token.json

# Generate with options
prove -t plonk -o custom.proof build/Token.json

# Generate and verify
prove --verify build/Token.json

# Using external service
PROOF_SERVICE_URL=https://api.example.com prove build/Token.json
```

### Using the verify command
```bash
# Verify a proof file
verify build/Token.proof

# Using midnight CLI
midnight verify build/Token.proof

# With external service
PROOF_SERVICE_URL=https://api.example.com verify build/Token.proof
```

### Batch processing with midnight CLI
```bash
# Compile all contracts
midnight compile

# Generate proofs for all compiled contracts
midnight prove

# The CLI automatically:
# - Finds all .json files in build/
# - Calls the proof service for each
# - Saves .proof files alongside
```

## Migration to Production

When moving to production:
1. Enable authentication
2. Configure SSL/TLS
3. Set up monitoring
4. Implement caching
5. Scale horizontally
6. Set `PROOF_SERVICE_URL` to production endpoint