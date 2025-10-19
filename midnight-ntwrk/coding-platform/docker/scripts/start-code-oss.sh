#!/bin/bash
# Wrapper script for starting Code OSS with appropriate port

# Check if we're in Cloud Workstations (they set specific environment variables)
if [ -n "$WORKSTATION_CLUSTER" ] || [ -n "$WORKSTATION_CONFIG" ] || [ -n "$GOOGLE_CLOUD_WORKSTATION" ]; then
    echo "Running in Cloud Workstations - using default port 80 configuration"
    # Let the base image's startup scripts handle it
    exec /google/scripts/entrypoint.sh "$@"
else
    echo "Running locally - replacing Code OSS startup to use port 8080"
    
    # Replace the Code OSS startup script with our version
    cat > /etc/workstation-startup.d/110_start-code-oss.sh << 'EOF'
#!/bin/bash
echo "Starting Code OSS on port 8080 (local mode)"

# Start Code OSS on port 8080 for local development
su user -c "cd /home/user && nohup /opt/code-oss/bin/codeoss-cloudworkstations \
    --port 8080 \
    --host 0.0.0.0 \
    --without-connection-token \
    --extensions-dir /home/user/.codeoss-cloudworkstations/extensions \
    --user-data-dir /home/user/.codeoss-cloudworkstations/data \
    --disable-telemetry \
    > /home/user/.codeoss-cloudworkstations/codeoss.log 2>&1 &"

echo "Code OSS started on port 8080"
EOF
    
    chmod +x /etc/workstation-startup.d/110_start-code-oss.sh
    
    # Start with the modified configuration
    exec /google/scripts/entrypoint.sh "$@"
fi