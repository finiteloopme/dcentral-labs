use std::sync::Arc;
use actix_web::{web, App, HttpResponse, HttpServer, Responder};
use serde::{Deserialize, Serialize};
use halo2_proofs::{
    plonk::{create_proof, keygen_pk, keygen_vk, verify_proof, ProvingKey, VerifyingKey},
    poly::commitment::Params,
    transcript::{Blake2bRead, Blake2bWrite, Challenge255},
    pasta::{EqAffine, Fp},
};
use rand::rngs::OsRng;
use base64::Engine as _;
use base64::engine::general_purpose::STANDARD;
use proof_service::{SudokuCircuit, SudokuConfig};
use log::info;

mod config;
use config::Config;

struct AppState {
    params: Arc<Params<EqAffine>>,
    pk: Arc<ProvingKey<EqAffine>>,
    vk: Arc<VerifyingKey<EqAffine>>,
}

#[derive(Deserialize)]
struct GenerateProofRequest {
    solution: [[u8; 9]; 9],
    puzzle: [[Option<u8>; 9]; 9],
    score: u64,
}

#[derive(Serialize)]
struct GenerateProofResponse {
    proof: String,
}

async fn generate_proof_handler(
    payload: web::Json<GenerateProofRequest>,
    data: web::Data<AppState>,
) -> impl Responder {
    info!("Received request to generate proof");

    let circuit = SudokuCircuit {
        solution: payload.solution,
        puzzle: payload.puzzle,
        score: payload.score,
    };

    let mut public_inputs: Vec<Fp> = payload.puzzle
        .iter()
        .flatten()
        .map(|&val| Fp::from(val.unwrap_or(0) as u64))
        .collect();
    public_inputs.push(Fp::from(payload.score));

    let mut transcript = Blake2bWrite::<_, _, Challenge255<_>>::init(vec![]);
    create_proof(&data.params, &data.pk, &[circuit], &[&[&public_inputs]], OsRng, &mut transcript)
        .expect("proof generation should not fail");
    let proof = transcript.finalize();

    let response = GenerateProofResponse {
        proof: STANDARD.encode(&proof),
    };
    info!("Proof generated successfully");
    HttpResponse::Ok().json(response)
}

#[derive(Deserialize)]
struct VerifyProofRequest {
    proof: String,
    puzzle: [[Option<u8>; 9]; 9],
    score: u64,
}

async fn verify_proof_handler(
    payload: web::Json<VerifyProofRequest>,
    data: web::Data<AppState>,
) -> impl Responder {
    info!("Received request to verify proof");

    let proof = match STANDARD.decode(&payload.proof.trim()) {
        Ok(p) => p,
        Err(e) => {
            info!("Base64 decoding failed: {}", e);
            return HttpResponse::BadRequest().json("Invalid base64 for proof");
        }
    };

    let mut public_inputs: Vec<Fp> = payload.puzzle
        .iter()
        .flatten()
        .map(|&val| Fp::from(val.unwrap_or(0) as u64))
        .collect();
    public_inputs.push(Fp::from(payload.score));

    let mut transcript = Blake2bRead::<_, _, Challenge255<_>>::init(&proof[..]);
    let strategy = halo2_proofs::plonk::SingleVerifier::new(&data.params);
    let result = verify_proof(
        &data.params,
        &data.vk,
        strategy,
        &[&[&public_inputs]],
        &mut transcript,
    );

    info!("Verification result: {:?}", result);

    HttpResponse::Ok().json(result.is_ok())
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info")).init();
    let config = Config::from_env();

    let params = Params::<EqAffine>::new(13);
    let empty_circuit = SudokuCircuit::default();
    let vk = keygen_vk(&params, &empty_circuit).expect("keygen_vk should not fail");
    let pk = keygen_pk(&params, vk.clone(), &empty_circuit).expect("keygen_pk should not fail");

    let app_state = web::Data::new(AppState {
        params: Arc::new(params),
        pk: Arc::new(pk),
        vk: Arc::new(vk),
    });

    HttpServer::new(move || {
        let cors = actix_cors::Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header();
        App::new()
            .app_data(app_state.clone())
            .wrap(cors)
            .route("/generate-proof", web::post().to(generate_proof_handler))
            .route("/verify-proof", web::post().to(verify_proof_handler))
    })
    .bind(format!("0.0.0.0:{}", config.port))?
    .keep_alive(std::time::Duration::from_secs(75))
    .run()
    .await
}