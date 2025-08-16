use actix_web::{get, web, App, HttpServer, Responder, HttpResponse};
use serde::Serialize;
use std::fs;
use std::path::Path;

// The path where the Confidential Space launcher places the attestation token.
const TOKEN_PATH: &str = "/run/container_launcher/attestation_verifier_claims_token";

#[derive(Serialize)]
struct TokenResponse {
    token: String,
}

#[derive(Serialize)]
struct ErrorResponse {
    error: String,
}

#[get("/token")]
async fn get_token() -> impl Responder {
    if !Path::new(TOKEN_PATH).exists() {
        let err = ErrorResponse {
            error: "Attestation token not found. The attestation process may not be complete or may have failed.".to_string(),
        };
        return HttpResponse::NotFound().json(err);
    }

    match fs::read_to_string(TOKEN_PATH) {
        Ok(token) => {
            let resp = TokenResponse { token };
            HttpResponse::Ok().json(resp)
        }
        Err(e) => {
            let err = ErrorResponse {
                error: format!("Failed to read token: {}", e),
            };
            HttpResponse::InternalServerError().json(err)
        }
    }
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    println!("Starting attestation server on http://0.0.0.0:8080");
    HttpServer::new(|| {
        App::new().service(get_token)
    })
    .bind(("0.0.0.0", 8080))?
    .run()
    .await
}
