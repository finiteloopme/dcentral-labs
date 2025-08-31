//! This module defines the shared application state.

use crate::models::{Competition, Game, Player};
use std::collections::HashMap;
use std::sync::{Arc, Mutex};

/// The shared application state.
///
/// This struct holds the data that needs to be shared across all requests.
/// It uses `Arc<Mutex<T>>` to ensure thread-safe access to the data.
/// In a production application, this would be replaced with a database connection pool.
#[derive(Clone)]
pub struct AppState {
    /// A map of competitions, with the competition ID as the key.
    pub competitions: Arc<Mutex<HashMap<String, Competition>>>,
    /// A list of all players.
    pub players: Arc<Mutex<Vec<Player>>>,
    /// A list of all games currently in progress.
    pub games: Arc<Mutex<Vec<Game>>>,
}

impl AppState {
    /// Creates a new instance of the application state.
    pub fn new() -> Self {
        Self {
            competitions: Arc::new(Mutex::new(HashMap::new())),
            players: Arc::new(Mutex::new(Vec::new())),
            games: Arc::new(Mutex::new(Vec::new())),
        }
    }
}
