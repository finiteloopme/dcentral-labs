// Protocol-specific implementations

use crate::BitVM3Protocol;

impl BitVM3Protocol {
    /// Create a new protocol instance with default configuration
    pub fn with_defaults() -> Self {
        Self::new()
    }
    
    /// Get protocol version
    pub fn version() -> &'static str {
        "0.1.0"
    }
}