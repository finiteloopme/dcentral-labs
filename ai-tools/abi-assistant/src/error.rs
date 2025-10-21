use std::error::Error;
use std::fmt;

/// Result type for the ABI Assistant
pub type Result<T> = std::result::Result<T, Box<dyn Error + Send + Sync>>;

/// Custom error type for ABI Assistant
#[derive(Debug)]
pub struct AbiAssistantError {
    message: String,
}

impl AbiAssistantError {
    pub fn new(message: impl Into<String>) -> Self {
        Self {
            message: message.into(),
        }
    }
}

impl fmt::Display for AbiAssistantError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", self.message)
    }
}

impl Error for AbiAssistantError {}