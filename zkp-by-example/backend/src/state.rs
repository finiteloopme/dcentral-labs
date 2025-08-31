use crate::models::{Competition, Game, Player};
use crate::config::Config;
use std::collections::HashMap;
use std::sync::{Arc, Mutex};

/// The shared application state.
#[derive(Clone)]
pub struct AppState {
    /// A map of competitions, with the competition ID as the key.
    pub competitions: Arc<Mutex<HashMap<String, Competition>>>,
    /// A list of all players.
    pub players: Arc<Mutex<Vec<Player>>>,
    /// A list of all games currently in progress.
    pub games: Arc<Mutex<Vec<Game>>>,
    /// The application configuration.
    pub config: Config,
}

impl AppState {
    /// Creates a new instance of the application state.
    pub fn new(config: Config) -> Self {
        Self {
            competitions: Arc::new(Mutex::new(HashMap::new())),
            players: Arc::new(Mutex::new(Vec::new())),
            games: Arc::new(Mutex::new(Vec::new())),
            config,
        }
    }
}
