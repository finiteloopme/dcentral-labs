//! Polygon Zero exex
use clap::Parser;
use db::{Database, Postgres, Sqlite};
use std::sync::Arc;

mod db;
mod error;
mod exex;
mod rpc;
mod tracer;

pub const DEFAULT_SQLITE_PATH: &str = "polygon-zero.db";
pub const DEFAULT_PG_URL: &str = "postgres://postgres@localhost:5432/postgres";

#[derive(Debug, Clone, Default, PartialEq, Eq, clap::Args)]
#[command(next_help_heading = "Zero Args")]
struct Args {
    /// The database type to be used for the zero tracer
    #[arg(
        long = "zeth.db-type",
        value_name = "DATABASE_TYPE",
        default_value = "sqlite"
    )]
    pub db_type: DatabaseType,
    /// The path / url to the database
    #[arg(long = "zeth.db-path", value_name = "DATABASE_PATH")]
    pub db_path: Option<String>,
}

#[derive(Default, Debug, Clone, PartialEq, Eq, clap::ValueEnum)]
enum DatabaseType {
    #[default]
    Sqlite,
    Postgres,
}

fn main() {
    use exex::ZeroTracerExEx;
    use reth::cli::Cli;
    use reth_node_ethereum::EthereumNode;
    use rpc::{ZeroTracerRpc, ZeroTracerRpcApiServer};

    // Enable backtraces unless a RUST_BACKTRACE value has already been explicitly provided.
    if std::env::var_os("RUST_BACKTRACE").is_none() {
        std::env::set_var("RUST_BACKTRACE", "1");
    }

    if let Err(err) = Cli::<Args>::parse().run(|builder, args| async move {
        let db = init_db(args).await?;
        let exex_db = db.clone();
        let handle = builder
            .node(EthereumNode::default())
            .install_exex("ZeroTracerExEx", move |ctx| async move {
                let exex = ZeroTracerExEx::new(ctx, exex_db)?;
                Ok(exex.run())
            })
            .extend_rpc_modules(move |ctx| {
                let zero_rpc = ZeroTracerRpc::new(db)?;
                ctx.modules.merge_configured(zero_rpc.into_rpc())?;
                Ok(())
            })
            .launch()
            .await?;

        handle.wait_for_node_exit().await
    }) {
        eprintln!("Error: {err:?}");
        std::process::exit(1);
    }
}

async fn init_db(args: Args) -> eyre::Result<Arc<dyn Database>> {
    Ok(match args.db_type {
        DatabaseType::Postgres => {
            Arc::new(Postgres::new(&args.db_path.unwrap_or(String::from(DEFAULT_PG_URL))).await?)
        }
        DatabaseType::Sqlite => {
            Arc::new(Sqlite::new(&args.db_path.unwrap_or(String::from(DEFAULT_SQLITE_PATH))).await?)
        }
    })
}
