package bigquery

import (
	"fmt"
	"reflect"
	"time"

	"cloud.google.com/go/bigquery"
	"github.com/apache/beam/sdks/v2/go/pkg/beam"
)

// BQEventRecord matches the schema for the main BigQuery table.
// Fields correspond to the consolidated DecodedEvent struct.
// Use STRING for addresses, hashes, URIs, and big.Ints for simplicity/compatibility.
// Use REPEATED STRING for slices of addresses.
type BQEventRecord struct {
	// Event parameters from DecodedEvent (nullable where pointers were used)
	Amount      string `bigquery:"amount"`       // STRING (from *big.Int)
	ProjectId   string `bigquery:"project_id"`   // STRING (from *big.Int) - standardizing name
	EpochNumber string `bigquery:"epoch_number"` // STRING (from *big.Int)

	Funder string `bigquery:"funder"` // STRING (from *common.Address)

	Recipient string `bigquery:"recipient"` // STRING (from *common.Address)

	Version string `bigquery:"version"` // STRING (from *big.Int)

	RequestEpochNumber string `bigquery:"request_epoch_number"` // STRING (from *big.Int)
	DiffAmmount        string `bigquery:"diff_ammount"`         // STRING (from *big.Int) - Typo?

	Owner string `bigquery:"owner"` // STRING (from *common.Address)

	RewardsRecipient string   `bigquery:"rewards_recipient"` // STRING (from *common.Address)
	MetadataUri      string   `bigquery:"metadata_uri"`      // STRING (from *string)
	ActiveFromEpoch  string   `bigquery:"active_from_epoch"` // STRING (from *big.Int)
	Contracts        []string `bigquery:"contracts"`         // REPEATED STRING (from *[]common.Address)

	ContractAddress string `bigquery:"contract_address_param"` // STRING (from *common.Address) - Renamed to avoid clash with metadata field

	EnabledOnEpochNumber string `bigquery:"enabled_on_epoch_number"` // STRING (from *big.Int)

	SuspendedOnEpochNumber string `bigquery:"suspended_on_epoch_number"` // STRING (from *big.Int)

	Limit string `bigquery:"limit"` // STRING (from *big.Int)

	Role              string `bigquery:"role"`                // STRING (from *common.Hash)
	PreviousAdminRole string `bigquery:"previous_admin_role"` // STRING (from *common.Hash)
	NewAdminRole      string `bigquery:"new_admin_role"`      // STRING (from *common.Hash)

	Account string `bigquery:"account"` // STRING (from *common.Address)
	Sender  string `bigquery:"sender"`  // STRING (from *common.Address)

	SfcAddress string `bigquery:"sfc_address"` // STRING (from *common.Address)

	Implementation string `bigquery:"implementation"` // STRING (from *common.Address)

	Fee string `bigquery:"fee"` // STRING (from *big.Int)

	// --- Base Metadata (Always Present) ---
	EventName                string    `bigquery:"event_name"`       // STRING (Required)
	EmittedByContractAddress string    `bigquery:"contract_address"` // STRING (Required) - The contract emitting the event
	BlockNumber              int64     `bigquery:"block_number"`     // INTEGER (Required)
	BlockHash                string    `bigquery:"block_hash"`       // STRING (Required)
	TxHash                   string    `bigquery:"tx_hash"`          // STRING (Required)
	TxIndex                  int       `bigquery:"tx_index"`         // INTEGER (Required)
	LogIndex                 int       `bigquery:"log_index"`        // INTEGER (Required)
	Removed                  bool      `bigquery:"removed"`          // BOOLEAN (Required)
	PipelineTime             time.Time `bigquery:"pipeline_time"`    // TIMESTAMP (Required)
}

// BQDuplicateRecord matches the schema for the duplicates table.
type BQDuplicateRecord struct {
	BQEventRecord
	DuplicateDetectionTime time.Time `bigquery:"duplicate_detection_time"` // TIMESTAMP (Required)
}

var (
	// Define schemas using beam reflection for use with bigqueryio.Write
	BQEventRecordSchema     bigquery.Schema
	BQDuplicateRecordSchema bigquery.Schema
)

func init() {
	// Register types for Beam serialization
	beam.RegisterType(reflect.TypeOf((*BQEventRecord)(nil)).Elem())
	beam.RegisterType(reflect.TypeOf((*BQDuplicateRecord)(nil)).Elem())

	// Infer schemas from structs
	// Use background context as schema inference happens at pipeline construction time
	// ctx := context.Background()
	var err error
	BQEventRecordSchema, err = bigquery.InferSchema(BQEventRecord{})

	if err != nil {
		panic(fmt.Sprintf("failed to infer schema for BQEventRecord: %v", err))
	}
	BQDuplicateRecordSchema, err = bigquery.InferSchema(BQDuplicateRecord{})
	if err != nil {
		panic(fmt.Sprintf("failed to infer schema for BQDuplicateRecord: %v", err))
	}
}
