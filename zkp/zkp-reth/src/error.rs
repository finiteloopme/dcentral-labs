#[derive(Debug, thiserror::Error)]
pub enum ZeroApiError {
    #[error("Block trace not found for block number: {0}")]
    TraceNotFoundForBlockNumber(u64),
    #[error("Block trace not found for block hash: {0}")]
    TraceNotFoundForBlockHash(String),
    #[error("Database error")]
    DatabaseError(#[from] DatabaseError),
}

#[derive(Debug, thiserror::Error)]
pub enum DatabaseError {
    #[error("Failed to commit zero trace to database: {0}")]
    InsertTrace(sqlx::Error),
    #[error("Failed to delete trace from database: {0}")]
    DeleteTrace(sqlx::Error),
    #[error("Failed to get trace from database: {0}")]
    GetTrace(sqlx::Error),
    #[error("Failed to create tables in database: {0}")]
    CreateTables(sqlx::Error),
    #[error("Failed to open database connection: {0}")]
    OpenConnection(sqlx::Error),
}

impl From<ZeroApiError> for jsonrpsee::types::error::ErrorObject<'static> {
    fn from(err: ZeroApiError) -> Self {
        match err {
            ZeroApiError::DatabaseError(_) => jsonrpsee::types::error::ErrorObject::owned(
                jsonrpsee::types::error::INTERNAL_ERROR_CODE,
                err.to_string(),
                None::<u8>,
            ),
            ZeroApiError::TraceNotFoundForBlockNumber(_) => {
                jsonrpsee::types::error::ErrorObject::owned(
                    jsonrpsee::types::error::INVALID_PARAMS_CODE,
                    err.to_string(),
                    None::<u8>,
                )
            }

            ZeroApiError::TraceNotFoundForBlockHash(_) => {
                jsonrpsee::types::error::ErrorObject::owned(
                    jsonrpsee::types::error::INVALID_PARAMS_CODE,
                    err.to_string(),
                    None::<u8>,
                )
            }
        }
    }
}
