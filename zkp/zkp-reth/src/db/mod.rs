use revm::primitives::FixedBytes;
use trace_decoder::BlockTrace;

use super::error::DatabaseError;

mod pg;
mod sqlite;

pub use pg::Postgres;
pub use sqlite::Sqlite;

#[async_trait::async_trait]
pub trait Database: Sync + Send {
    async fn commit_block_trace(
        &self,
        block_hash: FixedBytes<32>,
        block_number: u64,
        block_trace: BlockTrace,
    ) -> Result<(), DatabaseError>;

    async fn get_block_trace_by_hash(
        &self,
        block_hash: FixedBytes<32>,
    ) -> Result<Option<BlockTrace>, DatabaseError>;

    async fn get_block_trace_by_number(
        &self,
        block_number: u64,
    ) -> Result<Option<BlockTrace>, DatabaseError>;

    async fn delete_block_trace_by_hash(
        &self,
        block_hash: FixedBytes<32>,
    ) -> Result<(), DatabaseError>;
}
