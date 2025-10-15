#!/bin/bash
# Setup script for Vertex AI in OpenCode container

echo "Setting up Vertex AI for OpenCode..."

# Export environment variables for Vertex AI
export GOOGLE_CLOUD_PROJECT="${GOOGLE_CLOUD_PROJECT:-${CLOUDSDK_CORE_PROJECT}}"
export VERTEX_AI_LOCATION="${VERTEX_AI_LOCATION:-us-central1}"

# Ensure the environment variable is available for OpenCode
if [ -z "$GOOGLE_CLOUD_PROJECT" ]; then
    echo "Warning: GOOGLE_CLOUD_PROJECT is not set. Vertex AI models will not work."
    echo "Please set it using: export GOOGLE_CLOUD_PROJECT=your-project-id"
fi

# Create OpenCode rules directory for custom instructions
mkdir -p /home/developer/.opencode/rules

# Create Web3 development rules
cat > /home/developer/.opencode/rules/web3-development.md << 'EOF'
# Web3 Development Rules

You are an expert in Solidity, Foundry, and Ethereum development.

## Key Principles
- Always prioritize security in smart contract development
- Optimize for gas efficiency
- Follow established patterns (OpenZeppelin, etc.)
- Write comprehensive tests using Foundry

## Best Practices
- Check for reentrancy vulnerabilities
- Validate all inputs
- Use SafeMath or Solidity 0.8+ for arithmetic
- Implement proper access controls
- Document all functions clearly

## Foundry Commands
- Use `forge test` for testing
- Use `forge fmt` for formatting
- Use `forge build` for compilation
- Use `cast` for blockchain interactions
- Use `anvil` for local development

## Security Checklist
- [ ] No reentrancy vulnerabilities
- [ ] No integer overflow/underflow
- [ ] Proper access controls
- [ ] Input validation
- [ ] Event emission for state changes
- [ ] Gas optimization
EOF

# Create DeFi specific rules
cat > /home/developer/.opencode/rules/defi.md << 'EOF'
# DeFi Development Rules

When working with DeFi protocols:
- Consider liquidity management
- Implement proper slippage protection
- Handle oracle price feeds securely
- Account for MEV protection
- Implement emergency pause mechanisms
EOF

# Set proper permissions
chown -R developer:developer /home/developer/.opencode

echo "Vertex AI setup complete!"
echo ""
echo "Available models through Google Vertex AI:"
echo ""
echo "Gemini Models:"
echo "  - google-vertex/gemini-2.0-flash-exp (default)"
echo "  - google-vertex/gemini-2.0-flash-thinking-exp-1219"
echo "  - google-vertex/gemini-1.5-flash"
echo "  - google-vertex/gemini-1.5-flash-8b"
echo "  - google-vertex/gemini-1.5-pro"
echo "  - google-vertex/gemini-exp-1206"
echo ""
echo "Claude Models (via Vertex AI Model Garden):"
echo "  - google-vertex-anthropic/claude-3-5-sonnet@20241022"
echo "  - google-vertex-anthropic/claude-3-opus@20240229"
echo "  - google-vertex-anthropic/claude-3-haiku@20240307"
echo ""
echo "Note: Claude 4 models will be available when released on Vertex AI"
echo ""
echo "Current configuration:"
echo "  GOOGLE_CLOUD_PROJECT: ${GOOGLE_CLOUD_PROJECT:-[NOT SET]}"
echo "  VERTEX_AI_LOCATION: ${VERTEX_AI_LOCATION}"