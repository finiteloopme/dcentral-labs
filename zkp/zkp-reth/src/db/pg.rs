use super::{Database, DatabaseError};
use revm::primitives::FixedBytes;
use sqlx::{
    postgres::{PgPool, PgPoolOptions},
    Row,
};

use trace_decoder::BlockTrace;

#[derive(Debug, Clone)]
pub struct Postgres {
    pool: PgPool,
}

impl Postgres {
    pub async fn new(path: &str) -> Result<Self, DatabaseError> {
        let pool = PgPoolOptions::new()
            .max_connections(1)
            .connect(path)
            .await
            .map_err(DatabaseError::OpenConnection)?;
        let database = Self { pool };
        database.create_tables().await?;
        Ok(database)
    }

    async fn create_tables(&self) -> Result<(), DatabaseError> {
        sqlx::query(
            "CREATE TABLE IF NOT EXISTS block_trace (
                block_hash TEXT PRIMARY KEY,
                block_number INTEGER NOT NULL,
                block_trace TEXT NOT NULL
            )",
        )
        .execute(&self.pool)
        .await
        .map_err(DatabaseError::CreateTables)?;
        Ok(())
    }
}

#[async_trait::async_trait]
impl Database for Postgres {
    async fn commit_block_trace(
        &self,
        block_hash: FixedBytes<32>,
        block_number: u64,
        block_trace: BlockTrace,
    ) -> Result<(), DatabaseError> {
        sqlx::query(
            "INSERT INTO block_trace (block_hash, block_number, block_trace) VALUES ($1, $2, $3)",
        )
        .bind(block_hash.to_string())
        .bind(block_number as i64)
        .bind(serde_json::to_string(&block_trace).expect("block trace is serializable"))
        .execute(&self.pool)
        .await
        .map_err(DatabaseError::InsertTrace)?;
        Ok(())
    }

    /// Get block trace by block number.
    async fn get_block_trace_by_hash(
        &self,
        block_hash: FixedBytes<32>,
    ) -> Result<Option<BlockTrace>, DatabaseError> {
        let row = sqlx::query("SELECT block_trace FROM block_trace WHERE block_hash = $1")
            .bind(block_hash.to_string())
            .fetch_optional(&self.pool)
            .await
            .map_err(DatabaseError::GetTrace)?;

        if let Some(row) = row {
            let block_trace: String = row.try_get("block_trace").expect("column is well formed");
            Ok(Some(
                serde_json::from_str(&block_trace).expect("block trace is deserializable"),
            ))
        } else {
            Ok(None)
        }
    }

    /// Get block trace by block number.
    async fn get_block_trace_by_number(
        &self,
        block_number: u64,
    ) -> Result<Option<BlockTrace>, DatabaseError> {
        let row = sqlx::query("SELECT block_trace FROM block_trace WHERE block_number = $1")
            .bind(block_number as i64)
            .fetch_optional(&self.pool)
            .await
            .map_err(DatabaseError::GetTrace)?;

        if let Some(row) = row {
            let block_trace: String = row.try_get("block_trace").expect("column is well formed");
            Ok(Some(
                serde_json::from_str(&block_trace).expect("block trace is deserializable"),
            ))
        } else {
            Ok(None)
        }
    }

    async fn delete_block_trace_by_hash(
        &self,
        block_hash: FixedBytes<32>,
    ) -> Result<(), DatabaseError> {
        sqlx::query("DELETE FROM block_trace WHERE block_hash = $1")
            .bind(block_hash.to_string())
            .execute(&self.pool)
            .await
            .map_err(DatabaseError::DeleteTrace)?;
        Ok(())
    }
}
