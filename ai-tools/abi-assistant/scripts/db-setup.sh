#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/common.sh"

log_info "Setting up SQLite database..."

# Load environment
load_env

# Set database path
DATABASE_URL=${DATABASE_URL:-"sqlite://./data/abi_assistant.db"}
DB_PATH=${DATABASE_URL#sqlite://}
DB_DIR=$(dirname "$DB_PATH")

# Create database directory
ensure_dir "$DB_DIR"

log_info "Database path: $DB_PATH"

# Create database and initial schema
log_info "Creating database schema..."

sqlite3 "$DB_PATH" << 'EOF'
-- ABIs table: Store contract ABIs with metadata
CREATE TABLE IF NOT EXISTS abis (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    contract_address TEXT NOT NULL,
    chain_id INTEGER NOT NULL,
    abi_json TEXT NOT NULL,
    contract_name TEXT,
    protocol_name TEXT,
    protocol_type TEXT,
    verified_source TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(contract_address, chain_id)
);

-- Protocol registry: Store discovered protocols
CREATE TABLE IF NOT EXISTS protocols (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    protocol_id TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    subtype TEXT,
    confidence REAL DEFAULT 0.0,
    patterns_matched TEXT,
    common_operations TEXT,
    verified_by TEXT,
    usage_count INTEGER DEFAULT 0,
    success_rate REAL DEFAULT 0.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Intent patterns: Store successful intent mappings
CREATE TABLE IF NOT EXISTS intent_patterns (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    intent_text TEXT NOT NULL,
    intent_category TEXT NOT NULL,
    protocol_id TEXT,
    function_signature TEXT,
    parameters TEXT,
    success_count INTEGER DEFAULT 0,
    failure_count INTEGER DEFAULT 0,
    avg_gas_used INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Transaction simulations: Store simulation results
CREATE TABLE IF NOT EXISTS simulations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    transaction_hash TEXT UNIQUE,
    from_address TEXT NOT NULL,
    to_address TEXT NOT NULL,
    function_signature TEXT,
    calldata TEXT,
    value TEXT,
    gas_estimate INTEGER,
    simulation_status TEXT,
    error_message TEXT,
    simulated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Agent registry: Store agent information for network
CREATE TABLE IF NOT EXISTS agents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT UNIQUE NOT NULL,
    name TEXT,
    capabilities TEXT,
    reputation_score REAL DEFAULT 0.5,
    total_interactions INTEGER DEFAULT 0,
    successful_interactions INTEGER DEFAULT 0,
    specializations TEXT,
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_abis_address ON abis(contract_address);
CREATE INDEX IF NOT EXISTS idx_abis_protocol ON abis(protocol_name);
CREATE INDEX IF NOT EXISTS idx_protocols_type ON protocols(type);
CREATE INDEX IF NOT EXISTS idx_intent_category ON intent_patterns(intent_category);
CREATE INDEX IF NOT EXISTS idx_simulations_from ON simulations(from_address);
CREATE INDEX IF NOT EXISTS idx_agents_reputation ON agents(reputation_score);

-- Create triggers for updated_at
CREATE TRIGGER IF NOT EXISTS update_abis_timestamp 
AFTER UPDATE ON abis 
BEGIN
    UPDATE abis SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_protocols_timestamp 
AFTER UPDATE ON protocols 
BEGIN
    UPDATE protocols SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_intent_patterns_timestamp 
AFTER UPDATE ON intent_patterns 
BEGIN
    UPDATE intent_patterns SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- Insert some default protocol patterns
INSERT OR IGNORE INTO protocols (protocol_id, name, type, confidence) VALUES
    ('uniswap-v2-pattern', 'Uniswap V2 Compatible', 'amm', 0.95),
    ('uniswap-v3-pattern', 'Uniswap V3 Compatible', 'amm', 0.95),
    ('aave-v3-pattern', 'Aave V3 Compatible', 'lending', 0.95),
    ('compound-v3-pattern', 'Compound V3 Compatible', 'lending', 0.95),
    ('erc20-pattern', 'ERC20 Token', 'token', 1.0),
    ('erc721-pattern', 'ERC721 NFT', 'nft', 1.0),
    ('erc4626-pattern', 'ERC4626 Vault', 'vault', 1.0);

.tables
EOF

log_info "✅ Database setup complete!"
log_info "Database location: $DB_PATH"