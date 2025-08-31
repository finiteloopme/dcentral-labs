//! The main entry point for the Sudoku backend server.
//!
//! This module sets up the Axum web server and defines the API routes.

use axum::{
    routing::{get, post, put},
    Router,
};
use std::net::SocketAddr;
use tower_http::cors::{Any, CorsLayer};

mod handlers;
mod models;
mod state;

use state::AppState;

#[tokio::main]
async fn main() {
    // Initialize the shared state.
    let state = AppState::new();

    // Set up CORS middleware to allow requests from any origin.
    // This is useful for development, but should be configured more securely for production.
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    // Define the application routes.
    let app = Router::new()
        // A simple health check endpoint.
        .route("/", get(handlers::handler))
        // Admin routes for managing competitions.
        .route("/admin/competitions", post(handlers::create_competition))
        .route(
            "/admin/competitions/:id/pause",
            put(handlers::pause_competition),
        )
        .route(
            "/admin/competitions/:id/resume",
            put(handlers::resume_competition),
        )
        // Player routes for interacting with the game.
        .route("/competitions", get(handlers::list_competitions))
        .route("/competitions/:id", get(handlers::get_competition))
        .route("/competitions/:id/join", post(handlers::join_competition))
        .route("/competitions/:id/submit", post(handlers::submit_solution))
        .route("/competitions/:id/ladder", get(handlers::get_ladder))
        // Add the shared state to the application.
        .with_state(state)
        // Add the CORS middleware.
        .layer(cors);

    // Start the server.
    let addr = SocketAddr::from(([127, 0, 0, 1], 3000));
    println!("listening on {}", addr);
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}