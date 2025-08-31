//! This module loads the application configuration from environment variables.

use std::env;

/// The application configuration.
#[derive(Clone)]
pub struct Config {
    /// The port to listen on.
    pub port: u16,
}

impl Config {
    /// Loads the configuration from environment variables.
    pub fn from_env() -> Self {
        dotenvy::dotenv().ok();
        Self {
            port: env::var("PORT").unwrap_or_else(|_| "3001".to_string()).parse().expect("PORT must be a number"),
        }
    }
}
