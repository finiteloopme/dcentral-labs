#!/bin/bash
#
# Configure proof service environment for all sessions
#

echo "Configuring proof service environment..."

# Create profile.d script to ensure environment is available in all shells
cat > /etc/profile.d/proof-service.sh << EOF
#!/bin/bash
# Proof service configuration
export PROOF_SERVICE_MODE="${PROOF_SERVICE_MODE:-local}"
EOF

if [ "$PROOF_SERVICE_MODE" = "external" ]; then
    if [ -n "$PROOF_SERVICE_URL" ]; then
        echo "export PROOF_SERVICE_URL=\"$PROOF_SERVICE_URL\"" >> /etc/profile.d/proof-service.sh
        echo "Configured for external proof service: $PROOF_SERVICE_URL"
        
        if [ -n "$PROOF_SERVICE_API_KEY" ]; then
            echo "export PROOF_SERVICE_API_KEY=\"$PROOF_SERVICE_API_KEY\"" >> /etc/profile.d/proof-service.sh
            echo "  API key: [CONFIGURED]"
        fi
    else
        echo "Warning: PROOF_SERVICE_MODE is external but PROOF_SERVICE_URL is not set"
        echo "  Falling back to local proof service"
        echo "export PROOF_SERVICE_MODE=\"local\"" > /etc/profile.d/proof-service.sh
    fi
else
    echo "Configured for local proof service (simulation)"
fi

chmod +x /etc/profile.d/proof-service.sh
echo "✓ Proof service environment configured"