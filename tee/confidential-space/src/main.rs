use axum::{routing::get, Json, Router};
use serde::Serialize;
use std::net::SocketAddr;
use tracing::info;

#[derive(Serialize)]
struct HelloResponse {
    message: String,
    environment: String,
    timestamp: String,
}

#[derive(Serialize)]
struct HealthResponse {
    status: String,
}

async fn hello() -> Json<HelloResponse> {
    let environment =
        std::env::var("ENVIRONMENT").unwrap_or_else(|_| "unknown".to_string());

    Json(HelloResponse {
        message: "Hello from Confidential Space!".to_string(),
        environment,
        timestamp: chrono::Utc::now().to_rfc3339(),
    })
}

async fn health() -> Json<HealthResponse> {
    Json(HealthResponse {
        status: "healthy".to_string(),
    })
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "info".into()),
        )
        .json()
        .init();

    let app = Router::new()
        .route("/", get(hello))
        .route("/health", get(health));

    let addr = SocketAddr::from(([0, 0, 0, 0], 8080));
    info!("Starting server on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr)
        .await
        .expect("failed to bind listener");

    info!("Listening on {}", addr);

    axum::serve(listener, app)
        .await
        .expect("server error");
}
