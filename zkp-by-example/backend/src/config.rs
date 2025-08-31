//! This module loads the application configuration from environment variables.

use std::env;

/// The application configuration.
#[derive(Clone)]
pub struct Config {
    /// The URL of the proof service.
    pub proof_service_url: String,
    /// The port to listen on.
    pub port: u16,
}

impl Config {
    /// Loads the configuration from environment variables.
    pub fn from_env() -> Self {
        dotenvy::dotenv().ok();
        Self {
            proof_service_url: env::var("PROOF_SERVICE_URL").expect("PROOF_SERVICE_URL must be set"),
            port: env::var("PORT").unwrap_or_else(|_| "3000".to_string()).parse().expect("PORT must be a number"),
        }
    }
}
