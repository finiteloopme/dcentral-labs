use crate::state::AppState;
use crate::models::{Competition, Game, Player, CreateCompetitionPayload, JoinGamePayload, LadderEntry, ProofResponse};
use actix_web::{web, HttpResponse, Responder};
use reqwest;
use serde_json::json;
use log::info;

// Admin Handlers

pub async fn create_competition(state: web::Data<AppState>, payload: web::Json<CreateCompetitionPayload>) -> impl Responder {
    info!("Creating competition with name: {}", payload.name);
    let mut competitions = state.competitions.lock().unwrap();
    let id = uuid::Uuid::new_v4().to_string();

    let puzzle = sudoku::Sudoku::generate_unique();
    let board: Vec<Option<u8>> = puzzle.to_bytes().iter().map(|c| if *c == 0 { None } else { Some(*c) }).collect();
    let board = board.chunks(9).map(|s| s.to_vec()).collect();

    let competition = Competition {
        id: id.clone(),
        name: payload.name.clone(),
        is_paused: false,
        board,
    };
    competitions.insert(id, competition.clone());
    HttpResponse::Created().json(competition)
}

pub async fn pause_competition(state: web::Data<AppState>, id: web::Path<String>) -> impl Responder {
    let competition_id = id.into_inner();
    let mut competitions = state.competitions.lock().unwrap();
    if let Some(competition) = competitions.get_mut(&competition_id) {
        competition.is_paused = true;
        HttpResponse::Ok()
    } else {
        HttpResponse::NotFound()
    }
}

pub async fn resume_competition(state: web::Data<AppState>, id: web::Path<String>) -> impl Responder {
    let competition_id = id.into_inner();
    let mut competitions = state.competitions.lock().unwrap();
    if let Some(competition) = competitions.get_mut(&competition_id) {
        competition.is_paused = false;
        HttpResponse::Ok()
    } else {
        HttpResponse::NotFound()
    }
}

// Player Handlers

pub async fn list_competitions(state: web::Data<AppState>) -> impl Responder {
    let competitions = state.competitions.lock().unwrap();
    let competitions_vec: Vec<Competition> = competitions.values().cloned().collect();
    HttpResponse::Ok().json(competitions_vec)
}

pub async fn get_competition(state: web::Data<AppState>, id: web::Path<String>) -> impl Responder {
    let competition_id = id.into_inner();
    let competitions = state.competitions.lock().unwrap();
    let competition = competitions.get(&competition_id).cloned();
    if let Some(c) = competition {
        HttpResponse::Ok().json(c)
    } else {
        HttpResponse::NotFound().finish()
    }
}

pub async fn join_competition(state: web::Data<AppState>, id: web::Path<String>, payload: web::Json<JoinGamePayload>) -> impl Responder {
    let competition_id = id.into_inner();
    let mut players = state.players.lock().unwrap();
    let mut games = state.games.lock().unwrap();
    let competitions = state.competitions.lock().unwrap();

    let competition = match competitions.get(&competition_id) {
        Some(c) => c,
        None => return HttpResponse::NotFound().finish(),
    };

    if let Some(existing_player) = players.iter().find(|p| p.name == payload.name) {
        if let Some(existing_game) = games.iter().find(|g| g.player_id == existing_player.id && g.competition_id == competition_id) {
            return HttpResponse::Ok().json(existing_game.clone());
        }
    }

    let player_id = uuid::Uuid::new_v4().to_string();
    let new_player = Player {
        id: player_id.clone(),
        name: payload.name.clone(),
    };
    players.push(new_player);

    let game = Game {
        competition_id: competition_id,
        player_id,
        board: competition.board.clone(),
        score: 0,
    };

    games.push(game.clone());

    HttpResponse::Created().json(game)
}

pub async fn submit_solution(state: web::Data<AppState>, id: web::Path<String>, submission: web::Json<Game>) -> impl Responder {
    let competition_id = id.into_inner();
    let mut games = state.games.lock().unwrap();
    let competitions = state.competitions.lock().unwrap();

    let competition = match competitions.get(&competition_id) {
        Some(c) => c,
        None => return HttpResponse::NotFound().finish(),
    };

    if competition.is_paused {
        return HttpResponse::Forbidden().finish();
    }

    if let Some(game) = games.iter_mut().find(|g| g.competition_id == competition_id && g.player_id == submission.player_id) {
        game.board = submission.board.clone();
        game.score = calculate_score(game, competition);

        HttpResponse::Ok().json(game.clone())
    } else {
        HttpResponse::NotFound().finish()
    }
}

pub async fn get_ladder(state: web::Data<AppState>, id: web::Path<String>) -> impl Responder {
    let competition_id = id.into_inner();
    let games = state.games.lock().unwrap();
    let players = state.players.lock().unwrap();

    let mut ladder: Vec<LadderEntry> = games
        .iter()
        .filter(|g| g.competition_id == competition_id)
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

    HttpResponse::Ok().json(ladder)
}

async fn generate_proof_request(submission: &Game, competition: &Competition, proof_service_url: &str) -> Result<ProofResponse, reqwest::Error> {
    let client = reqwest::Client::new();
    let res = client.post(format!("{}/generate-proof", proof_service_url))
        .json(&json!({
            "player_board": submission.board,
            "solution_board": competition.board,
            "score": submission.score,
        }))
        .send()
        .await?;

    res.json::<ProofResponse>().await
}

pub async fn request_proof(state: web::Data<AppState>, submission: web::Json<Game>) -> impl Responder {
    let competitions = state.competitions.lock().unwrap();
    let competition = match competitions.get(&submission.competition_id) {
        Some(c) => c.clone(),
        None => return HttpResponse::NotFound().finish(),
    };

    match generate_proof_request(&submission, &competition, &state.config.proof_service_url).await {
        Ok(proof_response) => HttpResponse::Ok().json(proof_response),
        Err(_) => HttpResponse::InternalServerError().finish(),
    }
}

pub async fn handler() -> impl Responder {
    HttpResponse::Ok().body("Hello, World!")
}

fn calculate_score(game: &Game, competition: &Competition) -> i32 {
    let mut score = 0;
    for (row_idx, row) in game.board.iter().enumerate() {
        for (col_idx, &cell) in row.iter().enumerate() {
            if let Some(val) = cell {
                if val == competition.board[row_idx][col_idx].unwrap_or(0) {
                    score += 1;
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