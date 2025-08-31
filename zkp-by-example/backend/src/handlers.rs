//! This module contains the handlers for the API endpoints.

use crate::state::AppState;
use crate::models::{Competition, Game, Player, CreateCompetitionPayload, JoinGamePayload, LadderEntry};
use axum::{
    extract::State,
    http::StatusCode,
    Json,
};

// Admin Handlers

/// Creates a new competition.
///
/// A new Sudoku puzzle is generated for the competition.
pub async fn create_competition(
    State(state): State<AppState>,
    Json(payload): Json<CreateCompetitionPayload>,
) -> (StatusCode, Json<Competition>) {
    let mut competitions = state.competitions.lock().unwrap();
    let id = uuid::Uuid::new_v4().to_string();

    // Generate a new Sudoku puzzle.
    let puzzle = sudoku::Sudoku::generate_unique();
    let board: Vec<Option<u8>> = puzzle.to_bytes().iter().map(|c| if *c == 0 { None } else { Some(*c) }).collect();
    let board = board.chunks(9).map(|s| s.to_vec()).collect();

    let competition = Competition {
        id: id.clone(),
        name: payload.name,
        is_paused: false,
        board,
    };
    competitions.insert(id, competition.clone());
    (StatusCode::CREATED, Json(competition))
}

/// Pauses a competition.
///
/// When a competition is paused, players cannot make moves.
pub async fn pause_competition(
    State(state): State<AppState>,
    axum::extract::Path(id): axum::extract::Path<String>,
) -> StatusCode {
    let mut competitions = state.competitions.lock().unwrap();
    if let Some(competition) = competitions.get_mut(&id) {
        competition.is_paused = true;
        StatusCode::OK
    } else {
        StatusCode::NOT_FOUND
    }
}

/// Resumes a competition.
pub async fn resume_competition(
    State(state): State<AppState>,
    axum::extract::Path(id): axum::extract::Path<String>,
) -> StatusCode {
    let mut competitions = state.competitions.lock().unwrap();
    if let Some(competition) = competitions.get_mut(&id) {
        competition.is_paused = false;
        StatusCode::OK
    } else {
        StatusCode::NOT_FOUND
    }
}

// Player Handlers

/// Lists all available competitions.
pub async fn list_competitions(State(state): State<AppState>) -> Json<Vec<Competition>> {
    let competitions = state.competitions.lock().unwrap();
    let competitions_vec = competitions.values().cloned().collect();
    Json(competitions_vec)
}

/// Gets a single competition by its ID.
pub async fn get_competition(State(state): State<AppState>, axum::extract::Path(id): axum::extract::Path<String>) -> (StatusCode, Json<Option<Competition>>) {
    let competitions = state.competitions.lock().unwrap();
    let competition = competitions.get(&id).cloned();
    if competition.is_some() {
        (StatusCode::OK, Json(competition))
    } else {
        (StatusCode::NOT_FOUND, Json(None))
    }
}


/// Allows a player to join a competition.
///
/// If the player already exists in the competition, their existing game is returned.
/// Otherwise, a new player and game are created.
pub async fn join_competition(
    State(state): State<AppState>,
    axum::extract::Path(id): axum::extract::Path<String>,
    Json(payload): Json<JoinGamePayload>,
) -> (StatusCode, Json<Game>) {
    let mut players = state.players.lock().unwrap();
    let mut games = state.games.lock().unwrap();
    let competitions = state.competitions.lock().unwrap();

    let competition = match competitions.get(&id) {
        Some(c) => c,
        None => return (StatusCode::NOT_FOUND, Json(Game::default())),
    };

    // Check if a player with the same name already exists for this competition.
    if let Some(existing_player) = players.iter().find(|p| p.name == payload.name) {
        if let Some(existing_game) = games.iter().find(|g| g.player_id == existing_player.id && g.competition_id == id) {
            return (StatusCode::OK, Json(existing_game.clone()));
        }
    }

    // If the player does not exist, create a new player and game.
    let player_id = uuid::Uuid::new_v4().to_string();
    let new_player = Player {
        id: player_id.clone(),
        name: payload.name,
    };
    players.push(new_player);

    let game = Game {
        competition_id: id,
        player_id,
        board: competition.board.clone(),
        score: 0,
    };

    games.push(game.clone());

    (StatusCode::CREATED, Json(game))
}

/// Submits a player's solution for scoring.
///
/// The player's board is compared against the solution board.
/// The score is calculated and updated.
pub async fn submit_solution(
    State(state): State<AppState>,
    axum::extract::Path(id): axum::extract::Path<String>,
    Json(submission): Json<Game>,
) -> (StatusCode, Json<Game>) {
    let mut games = state.games.lock().unwrap();
    let competitions = state.competitions.lock().unwrap();

    let competition = match competitions.get(&id) {
        Some(c) => c,
        None => return (StatusCode::NOT_FOUND, Json(Game::default())),
    };

    // Players cannot submit solutions if the competition is paused.
    if competition.is_paused {
        return (StatusCode::FORBIDDEN, Json(Game::default()));
    }

    if let Some(game) = games.iter_mut().find(|g| g.competition_id == id && g.player_id == submission.player_id) {
        game.board = submission.board.clone();
        game.score = calculate_score(game, competition);

        (StatusCode::OK, Json(game.clone()))
    } else {
        (StatusCode::NOT_FOUND, Json(Game::default()))
    }
}

/// Returns the ladder for a competition.
///
/// The ladder is a list of all games in the competition, which includes the player and their score.
pub async fn get_ladder(State(state): State<AppState>, axum::extract::Path(id): axum::extract::Path<String>) -> (StatusCode, Json<Vec<LadderEntry>>) {
    let games = state.games.lock().unwrap();
    let players = state.players.lock().unwrap();

    let mut ladder: Vec<LadderEntry> = games
        .iter()
        .filter(|g| g.competition_id == id)
        .map(|g| {
            let player_name = players
                .iter()
                .find(|p| p.id == g.player_id)
                .map(|p| p.name.clone())
                .unwrap_or_else(|| "Unknown".to_string());
            LadderEntry {
                player_name,
                score: g.score,
            }
        })
        .collect();

    ladder.sort_by(|a, b| b.score.cmp(&a.score));

    (StatusCode::OK, Json(ladder))
}


/// A simple handler for the root endpoint.
pub async fn handler() -> &'static str {
    "Hello, World!"
}

fn calculate_score(game: &Game, competition: &Competition) -> i32 {
    let mut score = 0;
    for (row_idx, row) in game.board.iter().enumerate() {
        for (col_idx, &cell) in row.iter().enumerate() {
            if let Some(val) = cell {
                if val == competition.board[row_idx][col_idx].unwrap_or(0) {
                    score += 1;
                } else {
                    score -= 2;
                }
            }
        }
    }
    score
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::{Competition, Game};

    #[test]
    fn test_scoring() {
        let solution_board = vec![
            vec![Some(5), Some(3), None, None, Some(7), None, None, None, None],
            vec![Some(6), None, None, Some(1), Some(9), Some(5), None, None, None],
            vec![None, Some(9), Some(8), None, None, None, None, Some(6), None],
            vec![Some(8), None, None, None, Some(6), None, None, None, Some(3)],
            vec![Some(4), None, None, Some(8), None, Some(3), None, None, Some(1)],
            vec![Some(7), None, None, None, Some(2), None, None, None, Some(6)],
            vec![None, Some(6), None, None, None, None, Some(2), Some(8), None],
            vec![None, None, None, Some(4), Some(1), Some(9), None, None, Some(5)],
            vec![None, None, None, None, Some(8), None, None, Some(7), Some(9)],
        ];

        let competition = Competition {
            id: "test".to_string(),
            name: "test".to_string(),
            is_paused: false,
            board: solution_board,
        };

        // Test case 1: Correct submission
        let game1 = Game {
            competition_id: "test".to_string(),
            player_id: "player1".to_string(),
            board: competition.board.clone(),
            score: 0,
        };
        let mut score1 = 0;
        for row in &game1.board {
            for cell in row {
                if cell.is_some() {
                    score1 += 1;
                }
            }
        }
        assert_eq!(calculate_score(&game1, &competition), score1);

        // Test case 2: Incorrect submission
        let mut game2 = game1.clone();
        game2.board[0][0] = Some(1);
        assert_eq!(calculate_score(&game2, &competition), score1 - 3);

        // Test case 3: Partially filled board
        let mut game3 = game1.clone();
        game3.board[0][0] = None;
        assert_eq!(calculate_score(&game3, &competition), score1 - 1);
    }
}