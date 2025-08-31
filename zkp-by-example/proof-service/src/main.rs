use actix_web::{web, App, HttpResponse, HttpServer, Responder};
use serde::{Deserialize, Serialize};
use ark_bls12_381::Fr;
use ark_std::Zero;
use tracing::info;

mod config;
mod zkp;

use config::Config;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    tracing_subscriber::fmt::init();
    let config = Config::from_env();

    HttpServer::new(|| {
        App::new()
            .route("/", web::get().to(handler))
            .route("/generate-proof", web::post().to(generate_proof_handler))
            .route("/verify-proof", web::post().to(verify_proof_handler))
    })
    .bind(format!("0.0.0.0:{}", config.port))?
    .run()
    .await
}

async fn handler() -> impl Responder {
    HttpResponse::Ok().body("Hello, from proof-service!")
}

#[derive(Deserialize)]
struct GenerateProofRequest {
    player_board: Vec<Vec<Option<u8>>>,
    solution_board: Vec<Vec<Option<u8>>>,
    score: i32,
}

#[derive(Serialize)]
struct GenerateProofResponse {
    proof: String, // This will be a base64 encoded proof
    vk: String,    // This will be a base64 encoded verifying key
}

async fn generate_proof_handler(
    payload: web::Json<GenerateProofRequest>,
) -> impl Responder {
    info!("Received request to generate proof.");

    let circuit = zkp::SudokuCircuit {
        player_board: payload.player_board.clone(),
        solution_board: payload.solution_board.clone(),
        score: payload.score,
        solution_hash: Fr::zero(), // Dummy value for now
    };

    let (_proof, _, _vk) = zkp::generate_proof(circuit);

    let response = GenerateProofResponse {
        proof: "dummy_proof".to_string(),
        vk: "dummy_vk".to_string(),
    };

    info!("Proof generated successfully.");
    HttpResponse::Ok().json(response)
}

#[derive(Deserialize)]
struct VerifyProofRequest {
    proof: String,
    vk: String,
    public_inputs: Vec<u64>,
}

async fn verify_proof_handler(_payload: web::Json<VerifyProofRequest>) -> impl Responder {
    info!("Received request to verify proof.");
    let result = true; // Dummy result
    info!("Proof verification result: {}", result);
    HttpResponse::Ok().json(result)
}