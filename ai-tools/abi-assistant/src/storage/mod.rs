use rusqlite::{Connection, Result, OptionalExtension};
use std::error::Error;
use std::path::Path;
use tracing::{info, debug};

/// Initialize the database with required tables
pub async fn init_database(db_url: &str) -> Result<(), Box<dyn Error + Send + Sync>> {
    // Extract path from SQLite URL
    let path = if db_url.starts_with("sqlite://") {
        &db_url[9..]
    } else {
        db_url
    };
    
    // Create directory if it doesn't exist
    if let Some(parent) = Path::new(path).parent() {
        std::fs::create_dir_all(parent)?;
    }
    
    let conn = Connection::open(path)?;
    
    // Create ABIs table
    conn.execute(
        "CREATE TABLE IF NOT EXISTS abis (
            id INTEGER PRIMARY KEY,
            address TEXT NOT NULL UNIQUE,
            chain TEXT NOT NULL,
            name TEXT,
            abi TEXT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )",
        [],
    )?;
    
    // Create protocols table
    conn.execute(
        "CREATE TABLE IF NOT EXISTS protocols (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            type TEXT NOT NULL,
            confidence REAL,
            patterns TEXT,
            metadata TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )",
        [],
    )?;
    
    // Create intents table for learning
    conn.execute(
        "CREATE TABLE IF NOT EXISTS intents (
            id INTEGER PRIMARY KEY,
            intent_text TEXT NOT NULL,
            resolved_function TEXT,
            protocol TEXT,
            success BOOLEAN,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )",
        [],
    )?;
    
    // Create index on addresses
    conn.execute(
        "CREATE INDEX IF NOT EXISTS idx_abis_address ON abis(address)",
        [],
    )?;
    
    // Create index on protocol names
    conn.execute(
        "CREATE INDEX IF NOT EXISTS idx_protocols_name ON protocols(name)",
        [],
    )?;
    
    info!("Database initialized successfully at {}", path);
    
    Ok(())
}

/// Store an ABI in the database
pub async fn store_abi(
    conn: &Connection,
    address: &str,
    chain: &str,
    name: Option<&str>,
    abi: &str,
) -> Result<()> {
    conn.execute(
        "INSERT OR REPLACE INTO abis (address, chain, name, abi, updated_at)
         VALUES (?1, ?2, ?3, ?4, CURRENT_TIMESTAMP)",
        [address, chain, name.unwrap_or(""), abi],
    )?;
    
    debug!("Stored ABI for address {} on {}", address, chain);
    Ok(())
}

/// Retrieve an ABI from the database
pub async fn get_abi(conn: &Connection, address: &str, chain: &str) -> Result<Option<String>> {
    let mut stmt = conn.prepare(
        "SELECT abi FROM abis WHERE address = ?1 AND chain = ?2"
    )?;
    
    let abi = stmt.query_row([address, chain], |row| {
        row.get::<_, String>(0)
    }).optional()?;
    
    Ok(abi)
}

/// Store a protocol pattern
pub async fn store_protocol(
    conn: &Connection,
    name: &str,
    protocol_type: &str,
    confidence: f64,
    patterns: &str,
    metadata: &str,
) -> Result<()> {
    conn.execute(
        "INSERT OR REPLACE INTO protocols (name, type, confidence, patterns, metadata)
         VALUES (?1, ?2, ?3, ?4, ?5)",
        &[name, protocol_type, &confidence.to_string(), patterns, metadata],
    )?;
    
    debug!("Stored protocol {} of type {}", name, protocol_type);
    Ok(())
}

/// Record an intent resolution for learning
pub async fn record_intent(
    conn: &Connection,
    intent_text: &str,
    resolved_function: &str,
    protocol: &str,
    success: bool,
) -> Result<()> {
    conn.execute(
        "INSERT INTO intents (intent_text, resolved_function, protocol, success)
         VALUES (?1, ?2, ?3, ?4)",
        &[intent_text, resolved_function, protocol, &success.to_string()],
    )?;
    
    debug!("Recorded intent resolution: {} -> {}", intent_text, resolved_function);
    Ok(())
}