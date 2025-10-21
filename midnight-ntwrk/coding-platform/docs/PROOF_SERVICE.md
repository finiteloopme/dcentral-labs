# Proof Service Documentation

## Overview

The Midnight Development Platform includes an integrated mock proof server that runs automatically inside the workstation container on port 8081. This provides a simplified, zero-configuration approach for development.

## Architecture

### Mock Proof Server
- **Port**: 8081 (internal to container)
- **Startup**: Automatic via `/etc/workstation-startup.d/200_start-proof-server.sh`
- **Implementation**: Node.js mock server (`/usr/local/bin/proof-server.js`)
- **Purpose**: Development and testing without real ZK proof generation

### Command Integration
The `prove` and `verify` commands automatically detect the container environment and use the correct endpoint:
- **Inside container**: Uses `http://localhost:8081`
- **Outside container**: Falls back to simulation mode
- **Auto-detection**: Based on presence of `/.dockerenv` file

## Usage

### Basic Commands
```bash
# Generate a proof (automatically uses mock server in container)
prove circuit.json input.json

# Verify a proof
verify circuit.json proof.json
```

### In Makefiles
```makefile
prove:
	prove contracts/Token.compact inputs.json

verify:
	verify contracts/Token.compact proof.json
```

## Mock Server Endpoints

The mock proof server implements the Midnight v4.0.0 API:

- `GET /healthz` - Health check endpoint
- `POST /prove` - Generate mock proof
- `POST /verify` - Verify mock proof
- `GET /status` - Server status

## Development Workflow

1. **Container Start**: Mock server starts automatically
2. **Circuit Development**: Write and test Compact contracts
3. **Proof Generation**: Use `prove` command (mock proofs for fast iteration)
4. **Verification**: Use `verify` command to validate workflow

## Troubleshooting

### Check Server Status
```bash
# Inside container
proof-status

# Check if server is running
curl http://localhost:8081/healthz
```

### View Server Logs
```bash
# Check startup logs
cat /var/log/proof-server.log

# Check service status
ps aux | grep proof-server
```

### Common Issues

**Server not responding:**
- Check if port 8081 is available: `netstat -tlnp | grep 8081`
- Restart server: `proof-service-manager restart`

**Commands using simulation:**
- Verify you're inside the container
- Check `echo $PROOF_SERVICE_URL` (should be empty or localhost:8081)

## Production Considerations

This mock server is for development only. For production:
1. Replace mock server with official Midnight proof server binary
2. Configure appropriate resources (CPU, memory)
3. Set up proper monitoring and logging
4. Consider external proof service for scalability

## File Locations

- **Mock Server**: `/usr/local/bin/proof-server.js`
- **Startup Script**: `/etc/workstation-startup.d/200_start-proof-server.sh`
- **Commands**: `/usr/local/bin/prove`, `/usr/local/bin/verify`
- **Manager**: `/usr/local/bin/proof-service-manager`
- **Templates**: `/docker/templates-sdk/` (SDK-integrated examples)