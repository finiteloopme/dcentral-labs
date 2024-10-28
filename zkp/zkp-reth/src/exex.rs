use super::{db::Database, tracer::trace_block};
use reth_exex::{ExExContext, ExExEvent};
use reth_node_api::FullNodeComponents;
use reth_primitives::{Receipt, SealedBlockWithSenders};
use revm::{
    db::ExecutionTrace,
    primitives::{Account, Address, HashMap},
};
use std::sync::Arc;
use tracing::info;

/// ZeroTracerExEx
pub struct ZeroTracerExEx<Node: FullNodeComponents> {
    pub(crate) ctx: ExExContext<Node>,
    pub(crate) db: Arc<dyn Database>,
}

impl<Node: FullNodeComponents> ZeroTracerExEx<Node> {
    /// Construct a new ZeroTracerExEx instance.
    pub fn new(ctx: ExExContext<Node>, db: Arc<dyn Database>) -> eyre::Result<Self> {
        Ok(Self { ctx, db })
    }

    /// Run the ZeroTracerExEx.
    pub async fn run(mut self) -> eyre::Result<()> {
        while let Some(notification) = self.ctx.notifications.recv().await {
            if let Some(reverted_chain) = notification.reverted_chain() {
                for block in reverted_chain.blocks().values() {
                    self.revert_block(block).await?;
                }
            }

            if let Some(committed_chain) = notification.committed_chain() {
                for (((block, receipts), trace), tx_traces) in committed_chain
                    .blocks_and_receipts()
                    .zip(committed_chain.execution_outcome().traces.iter())
                    .zip(committed_chain.execution_outcome().tx_traces.iter())
                {
                    self.trace_and_commit_block(
                        block.clone(),
                        receipts.clone(),
                        trace.clone(),
                        tx_traces.clone(),
                    )
                    .await?;
                }
                self.ctx
                    .events
                    .send(ExExEvent::FinishedHeight(committed_chain.tip().number))?;
            }
        }
        Ok(())
    }

    /// Process a new block commit.
    pub(crate) async fn trace_and_commit_block(
        &mut self,
        block: SealedBlockWithSenders,
        receipts: Vec<Option<Receipt>>,
        trace: ExecutionTrace,
        tx_traces: Vec<HashMap<Address, Account>>,
    ) -> eyre::Result<()> {
        let block_number = block.header().number;
        let block_hash = block.hash();
        info!("Processing block {} - {}", block_number, block_hash);
        let block_trace = trace_block(&mut self.ctx, block, receipts, trace, tx_traces)?;
        self.db
            .commit_block_trace(block_hash, block_number, block_trace)
            .await?;
        Ok(())
    }

    /// Process a block revert.
    pub(crate) async fn revert_block(
        &mut self,
        block: &SealedBlockWithSenders,
    ) -> eyre::Result<()> {
        let block_hash = block.hash();
        info!("Reverting block {}", block_hash);
        self.db.delete_block_trace_by_hash(block_hash).await?;
        Ok(())
    }
}
