use actix_cors::Cors;
use actix_web::{web, App, HttpServer};
use log::info;

mod config;
mod handlers;
mod models;
mod state;

use config::Config;
use state::AppState;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info")).init();
    let config = Config::from_env();
    let state = web::Data::new(AppState::new(config.clone()));

    HttpServer::new(move || {
        let cors = Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header();

        App::new()
            .wrap(cors)
            .app_data(state.clone())
            .service(
                web::scope("/admin")
                    .route("/competitions", web::post().to(handlers::create_competition))
                    .route("/competitions/{id}/pause", web::put().to(handlers::pause_competition))
                    .route("/competitions/{id}/resume", web::put().to(handlers::resume_competition))
            )
            .service(
                web::scope("/competitions")
                    .route("", web::get().to(handlers::list_competitions))
                    .route("/{id}", web::get().to(handlers::get_competition))
                    .route("/{id}/join", web::post().to(handlers::join_competition))
                    .route("/{id}/submit", web::post().to(handlers::submit_solution))
                    .route("/{id}/ladder", web::get().to(handlers::get_ladder))
            )
            .route("/request-proof", web::post().to(handlers::request_proof))
            .route("/", web::get().to(handlers::handler))
    })
    .bind(format!("0.0.0.0:{}", config.port))?
    .run()
    .await
}
