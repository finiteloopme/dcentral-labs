#!/bin/bash
# startup_script.sh for GCP
# This script runs on the first boot of the GCE instance.

# --- Configuration ---
# Use the default user created by GCP for all operations
export USER=$(whoami)
export HOME="/home/$USER"
cd $HOME

# Data disk device path in GCP is typically /dev/sdb
DATA_DISK="/dev/sdb"
DATA_DIR="/mnt/data"

# --- Mount Data Disk ---
# Format and mount the attached persistent disk for chain data
mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard $DATA_DISK
mkdir -p $DATA_DIR
mount -o discard,defaults $DATA_DISK $DATA_DIR
chmod a+w $DATA_DIR # Make it writable for our user

# --- Dependencies ---
# Update package lists and install required tools
apt-get update
apt-get install -y zstd git curl build-essential

# Install Rust and Cargo
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

# --- Build Reth ---
git clone https://github.com/paradigmxyz/reth.git
cd reth
cargo build --release
cd $HOME

# --- Download Snapshot & Sync ---
RETH_MAINNET_DIR="$DATA_DIR/reth-mainnet-data"
mkdir -p $RETH_MAINNET_DIR

# Download the snapshot
wget https://snapshots.ethpandaops.io/mainnet/reth/23190000/snapshot.tar.zst -O snapshot.tar.zst

# Decompress into the data directory on the mounted disk
tar --use-compress-program="zstd -d" -xvf snapshot.tar.zst -C $RETH_MAINNET_DIR

# Clean up the compressed file
rm snapshot.tar.zst

# Correct the path if the tarball extracts with a nested structure
if [ -d "$RETH_MAINNET_DIR/mainnet/reth/db" ]; then
    mv $RETH_MAINNET_DIR/mainnet/reth/db/* $RETH_MAINNET_DIR/
fi


# --- Create Private Chain Artifacts ---
# NOTE: This section automates the "manual" steps from the guide.

# For this automated script, we will assume a target block number.
# In a real setup, you would SSH in and monitor the sync before proceeding.
TARGET_BLOCK="25000000"
PRIVATE_CHAIN_DIR="$DATA_DIR/reth-private-data"
RETH_BIN="$HOME/reth/target/release/reth"

# Create a JWT secret
openssl rand -hex 32 > $HOME/jwt.secret

# Run reth to sync past the target block. This will run as a background process.
# For this script, we'll let it sync for a while and then stop it.
echo "Starting Reth to sync from snapshot. This will run for 1 hour for demonstration."
nohup $RETH_BIN node \
  --chain mainnet \
  --datadir $RETH_MAINNET_DIR \
  --authrpc.jwtsecret $HOME/jwt.secret &> $HOME/reth-sync.log &
RETH_PID=$!

# Let it sync for a while (e.g., 1 hour). Adjust as needed.
sleep 3600
kill $RETH_PID

echo "Sync complete. Exporting private snapshot at block $TARGET_BLOCK."

# Export the local snapshot at the target block
$RETH_BIN db export \
  --datadir $RETH_MAINNET_DIR \
  --chain mainnet \
  --to $TARGET_BLOCK \
  $DATA_DIR/private-snapshot.rlp

# Get the genesis file from instance metadata
echo "Fetching genesis file from metadata..."
curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/genesis_json" \
  -H "Metadata-Flavor: Google" > $HOME/private-genesis.json

# Initialize the private data directory with the snapshot
$RETH_BIN init \
  --datadir $PRIVATE_CHAIN_DIR \
  --chain $HOME/private-genesis.json \
  --import $DATA_DIR/private-snapshot.rlp

# --- Run the Private, Permissioned Node ---
echo "Starting the private, permissioned Reth node."
# This will run as the main process for the machine going forward
nohup $RETH_BIN node \
  --chain $HOME/private-genesis.json \
  --datadir $PRIVATE_CHAIN_DIR \
  --nodiscovery \
  --port 30303 \
  --authrpc.port 8551 \
  --authrpc.jwtsecret $HOME/jwt.secret \
  --http --http.port 8545 --http.api "eth,net,web3,personal" \
  --ws --ws.port 8546 &> $HOME/reth-private.log &

echo "Setup complete. The private Reth node is running in the background."

# --- Output Connection Info ---
# Get the public IP from metadata and print the RPC URL
PUBLIC_IP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
RPC_URL="http://${PUBLIC_IP}:8545"

echo "-----------------------------------------------------"
echo "✅ Private Reth Node is Ready!"
echo "Connect wallets and DApps to the following RPC URL:"
echo $RPC_URL
echo "-----------------------------------------------------"
echo $RPC_URL > $HOME/rpc_url.txt

