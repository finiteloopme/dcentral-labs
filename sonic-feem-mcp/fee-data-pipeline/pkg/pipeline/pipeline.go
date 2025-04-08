package pipeline

import (
	"context"
	"fmt"

	"github.com/apache/beam/sdks/v2/go/pkg/beam"
	"github.com/apache/beam/sdks/v2/go/pkg/beam/io/bigqueryio"
	"github.com/apache/beam/sdks/v2/go/pkg/beam/log"
	"github.com/ethereum/go-ethereum/accounts/abi"

	"github.com/finiteloopme/dcentral-dev/sonic-feem-mcp/fee-data-pipeline/pkg/chain"
	"github.com/finiteloopme/dcentral-dev/sonic-feem-mcp/fee-data-pipeline/pkg/config"
)

// Build constructs the Beam pipeline graph.
func Build(s beam.Scope, cfg *config.Config, abiString string, parsedABI *abi.ABI) {
	s = s.Scope("SonicEventPipeline") // Add scope for clarity in UI

	// 1. Start with an impulse to trigger the source DoFn
	impulse := beam.Impulse(s)

	// 2. Read logs from Ethereum WebSocket (Custom Source)
	rawLogs := beam.ParDo(s.Scope("ReadLogs"), chain.NewEthLogStreamFn(cfg.WebsocketURL, cfg.ContractAddress), impulse)

	// 3. Decode Logs using the fetched ABI string
	// Pass the parsed ABI as well for potential use within the DoFn if needed,
	// but primarily rely on AbiJSON for setup.
	// decodeFn := newDecodeLogFn(abiString, parsedABI)
	decodedEvents := beam.ParDo(s.Scope("DecodeLogs"), &decodeLogFn{AbiJSON: abiString, parsedABI: parsedABI}, rawLogs)
	log.Infoln(context.Background(), "Decoded Events: ", decodedEvents)
	// 4. Prepare for Duplicate Check: Extract Key (TxHash:LogIndex)
	keyedEvents := beam.ParDo(s.Scope("ExtractKeyEvent"), &extractKeyEventFn{}, decodedEvents)

	// 5. Group by Key
	groupedEvents := beam.GroupByKey(s.Scope("GroupByKey"), keyedEvents)

	// 6. Filter Duplicates
	uniqueEvents, duplicateEvents := beam.ParDo2(s.Scope("FilterDuplicates"), &filterDuplicatesFn{}, groupedEvents)

	// 7. Convert Unique Events to BigQuery Format
	bqUniqueRecords := beam.ParDo(s.Scope("ConvertToUniqueBQRecord"), &convertToBQRecordFn{}, uniqueEvents)

	// 8. Write Unique Events to Main BigQuery Table
	uniqueTableSpec := fmt.Sprintf("%s:%s.%s", cfg.ProjectID, cfg.BQDataset, cfg.BQTable)
	bigqueryio.Write(
		s.Scope("WriteUniqueEvents"),
		cfg.ProjectID,
		uniqueTableSpec,
		bqUniqueRecords)
	// .WithSchema(bigquery.BQEventRecordSchema). // Use schema from bigquery package
	// WithCreateDisposition(bigqueryio.CreateIfNeeded).
	// WithWriteDisposition(bigqueryio.WriteAppend)

	// 9. Convert Duplicate Events to BigQuery Format
	bqDuplicateRecords := beam.ParDo(s.Scope("ConvertToDuplicateBQRecord"), &convertToBQDuplicateRecordFn{}, duplicateEvents)

	// 10. Write Duplicate Events to Duplicate BigQuery Table
	duplicateTableSpec := fmt.Sprintf("%s:%s.%s", cfg.ProjectID, cfg.BQDataset, cfg.BQDuplicateTable)
	bigqueryio.Write(
		s.Scope("WriteDuplicateEvents"),
		cfg.ProjectID,
		duplicateTableSpec,
		bqDuplicateRecords)
	// .WithSchema(bigquery.BQDuplicateRecordSchema). // Use schema from bigquery package
	// WithCreateDisposition(bigqueryio.CreateIfNeeded).
	// WithWriteDisposition(bigqueryio.WriteAppend)
}
