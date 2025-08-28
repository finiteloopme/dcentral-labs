#!/bin/bash
# startup_script.sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# --- Configuration ---
readonly DATA_DIR="/mnt/data"
readonly DATA_DISK="/dev/sdb"
readonly HOME="/root" # Running as root

#==============================================================================
# HELPER FUNCTIONS
#==============================================================================

install_dependencies() {
    # Idempotency check: skip if key dependencies are already installed.
    if command -v jq &> /dev/null && command -v curl &> /dev/null; then
        echo "Dependencies are already installed (jq and curl found). Skipping."
        return
    fi
    echo "Installing system dependencies..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y jq build-essential zstd libclang-dev libssl-dev pkg-config libpq-dev git curl
}

install_rust() {
    if command -v cargo &> /dev/null; then
        echo "Rust is already installed. Skipping."
        return
    fi
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
}

install_reth() {
    if [ -f "/usr/local/bin/reth" ]; then
        echo "Reth is already installed. Skipping."
        return
    fi
    echo "Installing Reth from source..."
    git clone https://github.com/paradigmxyz/reth
    cd reth
    cargo install --path ./bin/reth --locked --features=jemalloc
    cp ./target/release/reth /usr/local/bin
    cd "$HOME"
    rm -rf reth # Clean up source code
}

setup_data_disk() {
    echo "Setting up data disk..."
    mkdir -p "$DATA_DIR"
    chown -R root:root "$DATA_DIR"

    # Idempotency: Mount the disk if it's not already mounted.
    if ! mountpoint -q "$DATA_DIR"; then
        echo "Data disk not mounted at $DATA_DIR. Proceeding with mount setup."
        # Format the disk only if it doesn't have a filesystem.
        if ! blkid -s TYPE -o value "$DATA_DISK" >/dev/null 2>&1; then
            echo "Disk $DATA_DISK is not formatted. Formatting with ext4..."
            mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard "$DATA_DISK"
        else
            echo "Disk $DATA_DISK already has a filesystem."
        fi

        # Mount the disk.
        echo "Mounting $DATA_DISK at $DATA_DIR..."
        mount -o discard,defaults "$DATA_DISK" "$DATA_DIR"
        chmod a+w "$DATA_DIR"
    else
        echo "Data disk is already mounted at $DATA_DIR."
    fi

    # If the data directory is not empty, assume data is present and skip download.
    if [ -n "$(ls -A "$DATA_DIR")" ]; then
        echo "Data directory is not empty. Skipping snapshot download."
        return
    fi

    # The rest of this function is for a fresh, empty disk.
    echo "Data directory is empty. Downloading and decompressing snapshot."
    local SNAPSHOT_TAR_ZST="$DATA_DIR/snapshot.tar.zst"
    echo "Downloading Reth mainnet snapshot from Google Cloud Storage..."
    gsutil cp gs://kl-reth-snapshot/23190000/snapshot.tar.zst "$SNAPSHOT_TAR_ZST"

    echo "Decompressing snapshot... (this will take a while)"
    tar --use-compress-program=unzstd -xvf "$SNAPSHOT_TAR_ZST" -C "$DATA_DIR"

    echo "Cleaning up snapshot file..."
    rm "$SNAPSHOT_TAR_ZST"
}

initialize_private_fork() {
    echo "Initializing private fork..."
    local genesis_file="$DATA_DIR/private-genesis.json"
    local datadir="$DATA_DIR/private_node"
    
    # Check if initialization has already been done
    if [ -f "$datadir/reth.toml" ]; then
        echo "Private fork already initialized. Skipping."
        return
    fi
    
    GENESIS_JSON=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/genesis-json)
    echo "$GENESIS_JSON" > "$genesis_file"

    "$HOME/.cargo/bin/reth" init --datadir "$datadir" --chain "$genesis_file"
}

setup_systemd_service() {
    # Idempotency check: if the service is already running, do nothing.
    if systemctl is-active --quiet reth.service; then
        echo "Reth systemd service is already active. Skipping setup."
        return
    fi

    echo "Creating systemd service for Reth node..."
    cat <<EOF > /etc/systemd/system/reth.service
[Unit]
Description=Reth Private Fork Node
After=network.target

[Service]
User=root
WorkingDirectory=$HOME
ExecStart=/usr/local/bin/reth node \
  --datadir $DATA_DIR/private_node \
  --chain $DATA_DIR/private-genesis.json \
  --http --http.addr 0.0.0.0 --http.port 8545 --http.api "eth,net,web3" \
  --ws --ws.addr 0.0.0.0 --ws.port 8546
Restart=always
RestartSec=5
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

    echo "Enabling and starting private Reth node via systemd..."
    systemctl daemon-reload
    systemctl enable reth.service
    systemctl start reth.service
}

output_connection_info() {
    echo "Setup complete. The private Reth node is running as a systemd service."
    echo "You can check its status with: systemctl status reth.service"
    echo "You can view logs with: journalctl -u reth.service -f"

    local public_ip
    public_ip=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
    local rpc_url="http://${public_ip}:8545"

    echo "-----------------------------------------------------"
    echo "✅ Private Reth Node is Ready!"
    echo "Connect wallets and DApps to the following RPC URL:"
    echo "$rpc_url"
    echo "-----------------------------------------------------"
    echo "$rpc_url" > "$HOME/rpc_url.txt"
}

#==============================================================================
# MAIN EXECUTION
#==============================================================================

main() {
    install_dependencies
    install_rust
    install_reth
    setup_data_disk
    initialize_private_fork
    setup_systemd_service
    output_connection_info
}

main