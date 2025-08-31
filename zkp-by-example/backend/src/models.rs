//! This module defines the data structures used throughout the application.

use serde::{Deserialize, Serialize};

/// Represents a single Sudoku competition.
#[derive(Serialize, Deserialize, Clone)]
pub struct Competition {
    /// A unique identifier for the competition.
    pub id: String,
    /// The name of the competition.
    pub name: String,
    /// Whether the competition is currently paused.
    pub is_paused: bool,
    /// The Sudoku board for the competition.
    /// `None` represents an empty cell.
    pub board: Vec<Vec<Option<u8>>>,
}

/// Represents a player in the game.
#[derive(Serialize, Deserialize, Clone)]
pub struct Player {
    /// A unique identifier for the player.
    pub id: String,
    /// The name of the player.
    pub name: String,
}

/// Represents a game in progress for a specific player and competition.
#[derive(Serialize, Deserialize, Clone, Default)]
pub struct Game {
    /// The ID of the competition this game belongs to.
    pub competition_id: String,
    /// The ID of the player playing this game.
    pub player_id: String,
    /// The player's current state of the Sudoku board.
    pub board: Vec<Vec<Option<u8>>>,
    /// The player's current score.
    pub score: i32,
}

/// The payload for creating a new competition.
#[derive(Deserialize)]
pub struct CreateCompetitionPayload {
    pub name: String,
}

/// The payload for joining a game.
#[derive(Deserialize)]
pub struct JoinGamePayload {
    pub name: String,
}

/// Represents an entry in the competition ladder.
#[derive(Serialize, Clone)]
pub struct LadderEntry {
    pub player_name: String,
    pub score: i32,
}

#[derive(Serialize, Deserialize)]
pub struct ProofResponse {
    pub proof: String,
    pub vk: String,
}
