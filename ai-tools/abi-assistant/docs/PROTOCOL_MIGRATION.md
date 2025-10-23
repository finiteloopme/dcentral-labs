# Protocol Configuration Migration Strategy

## Current State (Phase 2)

The `intent.protocols` configuration in `mcp-default-config.toml` is used for **name normalization only**:

```toml
[intent.protocols]
# Maps user input variations to canonical names
uniswap = ["Uniswap", "UniswapV2", "UniswapV3", "uni"]
```

### How It Works Now

1. **User Input**: "swap on uni"
2. **Normalization**: "uni" → "Uniswap"
3. **Registry Lookup**: Find pre-registered Uniswap protocols
4. **Return Suggestions**: Uniswap V3, Uniswap V2

The actual protocol definitions are currently hardcoded in:
- `src/intent/registry.rs` - Protocol registry with addresses
- `src/intent/resolver.rs` - Protocol-to-function mappings

## Future State (Phase 4: Dynamic Discovery)

### Configuration Evolution

```toml
[intent.protocols]
# Phase 4: This section becomes optional hints/overrides

# User preferences (optional)
preferred = ["Uniswap V3", "Aave V3"]
blacklist = ["Unknown Protocol X"]

# Name normalization still useful
aliases = {
    uni = "Uniswap",
    sushi = "Sushiswap"
}

[intent.discovery]
# New section for dynamic discovery
enabled = true

# Discovery sources
sources = [
    "onchain",      # Read from blockchain
    "etherscan",    # Verified contracts
    "graph",        # The Graph Protocol
    "defillama",    # DeFi protocol data
    "community"     # Community registry
]

# Caching discovered protocols
cache_duration = 86400  # 24 hours
auto_refresh = true

# Filtering rules
min_tvl = 1000000      # $1M minimum
require_audit = false
max_age_days = 365
```

### How It Will Work

1. **User Input**: "swap on NewProtocolXYZ"
2. **Check Cache**: Is NewProtocolXYZ already discovered?
3. **Dynamic Discovery** (if not cached):
   ```rust
   // Pseudocode
   let protocol = discovery_engine
       .find_protocol("NewProtocolXYZ")
       .or_fetch_from_chain(address)
       .or_search_etherscan(name)
       .or_query_graph_protocol()?;
   ```
4. **Pattern Recognition**: Analyze ABI to determine capabilities
5. **Generate Mappings**: Auto-create function mappings
6. **Cache Results**: Store for future use
7. **Return Suggestions**: With confidence scores

## Migration Path

### Phase 2 → Phase 3 (Transitional)
No breaking changes. The config remains the same, but we add:
- Protocol discovery interface (already implemented)
- Mock discovery for testing
- Fallback to hardcoded protocols

### Phase 3 → Phase 4 (Dynamic)
1. **Backward Compatible**: Old configs still work
2. **Progressive Enhancement**: New features are opt-in
3. **Gradual Migration**:
   ```toml
   [intent.discovery]
   enabled = false  # Start disabled
   fallback_to_registry = true  # Use old registry as fallback
   ```

## Code Architecture for Migration

### Current (Phase 2)
```rust
// Hardcoded protocols
impl ProtocolRegistry {
    fn load_default_protocols(&mut self) {
        self.register_protocol(Protocol {
            name: "Uniswap V3",
            address: "0x68b3...",
            // ... hardcoded
        });
    }
}
```

### Future (Phase 4)
```rust
// Dynamic discovery
impl DynamicProtocolRegistry {
    async fn get_protocol(&self, identifier: &str) -> Result<Protocol> {
        // Try cache first
        if let Some(cached) = self.cache.get(identifier) {
            return Ok(cached);
        }
        
        // Try various discovery methods
        let protocol = self.discover_from_sources(identifier).await?;
        
        // Cache for future use
        self.cache.insert(identifier, protocol.clone());
        
        Ok(protocol)
    }
    
    async fn discover_from_sources(&self, id: &str) -> Result<Protocol> {
        // Try each configured source
        for source in &self.config.discovery.sources {
            if let Ok(protocol) = source.discover(id).await {
                return Ok(protocol);
            }
        }
        
        // Fallback to registry if enabled
        if self.config.discovery.fallback_to_registry {
            return self.static_registry.get(id);
        }
        
        Err(NotFound)
    }
}
```

## Benefits of This Approach

1. **No Breaking Changes**: Existing configs continue to work
2. **Progressive Enhancement**: Users can opt into dynamic discovery
3. **Performance**: Caching prevents repeated discoveries
4. **Flexibility**: Multiple discovery sources with fallbacks
5. **User Control**: Can still prefer/blacklist protocols

## Configuration Examples

### Conservative User (prefers known protocols)
```toml
[intent.discovery]
enabled = false  # Stay with hardcoded protocols
```

### Advanced User (full dynamic discovery)
```toml
[intent.discovery]
enabled = true
sources = ["onchain", "graph", "community"]
auto_approve_verified = true
```

### DeFi Developer (testing new protocols)
```toml
[intent.discovery]
enabled = true
sources = ["onchain"]  # Direct from blockchain
require_audit = false  # Allow unaudited
min_tvl = 0  # No TVL requirement
```

## Timeline

- **Phase 2** ✅: Static registry with name normalization
- **Phase 3** (next): Add discovery interface, keep static defaults
- **Phase 4**: Implement dynamic discovery with caching
- **Phase 5**: Community registry and protocol sharing

## Summary

The `intent.protocols` configuration is designed to evolve from:
- **Now**: Simple name mappings for normalization
- **Future**: Optional hints/preferences with dynamic discovery

This ensures smooth migration without breaking existing configurations while enabling powerful dynamic protocol discovery in the future.