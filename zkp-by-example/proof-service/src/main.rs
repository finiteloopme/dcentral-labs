//! This module contains the main entry point for the proof service.
//!
//! The proof service is an Actix web server that exposes a single endpoint:
//! - `POST /generate-proof`: Generates a proof for a given Sudoku board.
//!
//! The `generate-proof` endpoint takes a JSON payload with the following format:
//! ```json
//! {
//!   "board": [[...]]
//! }
//! ```
//!
//! The `board` is the player's submitted Sudoku board.
//!
//! The endpoint returns a JSON payload with the following format:
//! ```json
//! {
//!   "proof": "..."
//! }
//! ```
//!
//! The `proof` is a base64-encoded string that contains the generated proof.

use actix_web::{web, App, HttpResponse, HttpServer, Responder};
use serde::{Deserialize, Serialize};
use halo2_proofs::{
    plonk::{create_proof, keygen_pk, keygen_vk},
    poly::commitment::Params,
    transcript::{Blake2bWrite, Challenge255},
};
use rand::rngs::OsRng;
use base64::Engine as _;
use base64::engine::general_purpose::STANDARD;
use proof_service::{SudokuCircuit};
use log::info;

/// The request payload for the `generate-proof` endpoint.
#[derive(Deserialize)]
struct GenerateProofRequest {
    /// The player's submitted Sudoku board.
    board: [[Option<u8>; 9]; 9],
}

/// The response payload for the `generate-proof` endpoint.
#[derive(Serialize)]
struct GenerateProofResponse {
    /// The base64-encoded proof.
    proof: String,
}

/// The handler for the `generate-proof` endpoint.
///
/// This function takes a `GenerateProofRequest` and returns a `GenerateProofResponse`.
/// The function performs the following steps:
/// 1. Generates the parameters for the circuit.
/// 2. Generates the proving and verification keys.
/// 3. Creates a new `SudokuCircuit` with the player's board and a dummy solution board.
/// 4. Generates a proof for the circuit.
/// 5. Encodes the proof as a base64 string.
/// 6. Returns the proof in a `GenerateProofResponse`.
async fn generate_proof_handler(
    payload: web::Json<GenerateProofRequest>,
) -> impl Responder {
    info!("Received request to generate proof");
    // TODO: This should be done only once and the parameters should be cached.
    // Generate the parameters for the circuit.
    // The `k` parameter is the size of the circuit.
    // The `2^k` is the number of rows in the circuit.
    let params: Params<halo2_proofs::pasta::EqAffine> = Params::new(13);

    // Create an empty circuit.
    let empty_circuit = SudokuCircuit::default();
    // Generate the verification key.
    let vk = keygen_vk(&params, &empty_circuit).expect("keygen_vk should not fail");
    // Generate the proving key.
    let pk = keygen_pk(&params, vk, &empty_circuit).expect("keygen_pk should not fail");

    // Using a dummy solution board for now.
    let solution_board = [[0u8; 9]; 9];

    // Create a new circuit with the player's board and the solution board.
    let circuit = SudokuCircuit {
        player_board: payload.board.clone(),
        solution_board,
    };

    // Create a new transcript.
    let mut transcript = Blake2bWrite::<_, _, Challenge255<_>>::init(vec![]);
    // Create a proof for the circuit.
    create_proof(&params, &pk, &[circuit], &[&[]], OsRng, &mut transcript)
        .expect("proof generation should not fail");
    // Finalize the transcript and get the proof.
    let proof = transcript.finalize();

    // Create the response.
    let response = GenerateProofResponse {
        proof: STANDARD.encode(&proof),
    };
    info!("Proof generated successfully");
    // Return the response.
    HttpResponse::Ok().json(response)
}

/// The main entry point for the proof service.
#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Initialize the logger.
    env_logger::init();
    // Create a new Actix web server.
    HttpServer::new(|| {
        // Create a new CORS middleware.
        let cors = actix_cors::Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header();
        // Create a new Actix web application.
        App::new()
            .wrap(cors)
            .route("/generate-proof", web::post().to(generate_proof_handler))
    })
    .bind("127.0.0.1:3001")?
    .keep_alive(std::time::Duration::from_secs(75))
    .run()
    .await
}