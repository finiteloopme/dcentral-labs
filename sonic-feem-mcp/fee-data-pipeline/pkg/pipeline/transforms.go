package pipeline

import (
	"context"
	"fmt"
	"math/big"
	"strings"
	"time"

	"github.com/apache/beam/sdks/v2/go/pkg/beam/log"
	"github.com/apache/beam/sdks/v2/go/pkg/beam/register"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"

	"github.com/finiteloopme/dcentral-dev/sonic-feem-mcp/fee-data-pipeline/pkg/bigquery" // Import sibling package
	"github.com/finiteloopme/dcentral-dev/sonic-feem-mcp/fee-data-pipeline/pkg/chain"    // Import sibling package
)

// --- Decode Log DoFn ---
type decodeLogFn struct {
	// Pass ABI string for Setup, as abi.ABI isn't easily serialized by Beam.
	AbiJSON string `json:"abiJson"`
	// Keep parsed ABI for use within ProcessElement after Setup. Non-serialized.
	parsedABI *abi.ABI `json:"-"`
}

// newDecodeLogFn creates the DoFn, ensuring AbiJSON is set.
func newDecodeLogFn(abiJSON string, parsedABI *abi.ABI) *decodeLogFn {
	return &decodeLogFn{
		AbiJSON:   abiJSON,
		parsedABI: parsedABI, // Store for use after Setup
	}
}

// Setup parses the ABI JSON string once when the DoFn is initialized on a worker.
func (fn *decodeLogFn) Setup() error {
	if fn.AbiJSON == "" {
		return fmt.Errorf("ABI JSON string is empty in decodeLogFn Setup")
	}
	parsedABI, err := abi.JSON(strings.NewReader(fn.AbiJSON))
	if err != nil {
		return fmt.Errorf("failed to parse ABI JSON in Setup: %w", err)
	}
	fn.parsedABI = &parsedABI
	return nil
}

// ProcessElement decodes a raw log using the contract ABI.
func (fn *decodeLogFn) ProcessElement(ctx context.Context, logEntry types.Log, emit func(chain.DecodedEvent)) error {
	if fn.parsedABI == nil {
		log.Errorf(ctx, "Decoder: ABI not initialized for log %s:%d", logEntry.TxHash.Hex(), logEntry.Index)
		return fmt.Errorf("ABI not initialized") // Should not happen if Setup worked
	}
	if len(logEntry.Topics) == 0 {
		log.Warnf(ctx, "Decoder: Log entry %s:%d has no topics, cannot decode event.", logEntry.TxHash.Hex(), logEntry.Index)
		return nil // Skip logs without topics
	}

	eventSig := logEntry.Topics[0] // First topic is usually the event signature hash

	event, err := fn.parsedABI.EventByID(eventSig)
	if err != nil {
		log.Warnf(ctx, "Decoder: Log %s:%d: No matching event found in ABI for signature %s", logEntry.TxHash.Hex(), logEntry.Index, eventSig.Hex())
		return nil // Skip logs for events not in the ABI
	}

	// Found matching event in ABI
	decoded := chain.DecodedEvent{
		Log:       logEntry,
		EventName: event.Name,
	}

	// --- Unpack Event Data ---
	unpackedData := make(map[string]interface{})
	if !event.Anonymous {
		// Unpack non-indexed fields from log.Data
		err = fn.parsedABI.UnpackIntoMap(unpackedData, event.Name, logEntry.Data)
		if err != nil {
			log.Errorf(ctx, "Decoder: Failed to unpack non-indexed data for event '%s' (log %s:%d): %v", event.Name, logEntry.TxHash.Hex(), logEntry.Index, err)
			// stats.Count(ctx, "decode_unpack_error", 1)
			return nil
		}
	}

	// Unpack indexed fields from log.Topics
	// Handle indexed topics
	topicIndex := 1 // Start from 1, as Topic[0] is the signature
	for _, arg := range event.Inputs {
		if arg.Indexed {
			if topicIndex >= len(logEntry.Topics) {
				log.Errorf(ctx, "Decoder: Mismatched indexed topics for event '%s' (log %s:%d). Expected more topics.", event.Name, logEntry.TxHash.Hex(), logEntry.Index)
				// stats.Count(ctx, "decode_topic_mismatch", 1)
				return nil // Skip malformed events
			}
			// Add indexed arguments to the map. Conversion might be needed depending on type.
			// common.Hash can represent address, bytes32, etc. Need type info from ABI.
			// Example: For address, convert hash to address.
			if arg.Type.T == abi.AddressTy {
				unpackedData[arg.Name] = common.BytesToAddress(logEntry.Topics[topicIndex].Bytes())
			} else {
				// Store the raw hash or handle other indexed types (bytes32, uint, etc.)
				// Let's refine this: attempt to convert based on type
				switch arg.Type.T {
				case abi.IntTy, abi.UintTy:
					// Convert topic hash to big.Int (assuming it fits)
					// Note: This might not be standard practice for indexed uint/int unless they are small enough.
					// Usually, large indexed numbers might not be directly represented in topics this way.
					// Check how your specific contract handles indexed numbers.
					// If they are just hashes of the numbers, this won't work directly.
					val := new(big.Int).SetBytes(logEntry.Topics[topicIndex].Bytes())
					unpackedData[arg.Name] = val
				case abi.BoolTy:
					// Booleans in topics are usually 1 or 0
					val := new(big.Int).SetBytes(logEntry.Topics[topicIndex].Bytes())
					unpackedData[arg.Name] = (val.Cmp(big.NewInt(0)) != 0) // true if not zero
				case abi.BytesTy, abi.FixedBytesTy, abi.StringTy:
					// For indexed bytes or string, the topic often contains the hash of the data,
					// not the data itself. You might only be able to store the hash.
					unpackedData[arg.Name] = logEntry.Topics[topicIndex] // Store as common.Hash
				default:
					// Default to storing the hash if type is unknown/complex
					unpackedData[arg.Name] = logEntry.Topics[topicIndex] // Store as common.Hash
				}
			}
			topicIndex++
		}
	}

	// --- Map Unpacked Data to DecodedEvent Struct ---
	// Use a switch statement for clarity and maintainability
	switch decoded.EventName {
	case "FundsAdded":
		if v, ok := unpackedData["funder"].(common.Address); ok {
			decoded.Funder = &v
		}
		if v, ok := unpackedData["amount"].(*big.Int); ok {
			decoded.Amount = v
		}
	case "FundsWithdrawn":
		if v, ok := unpackedData["recipient"].(common.Address); ok {
			decoded.Recipient = &v
		}
		if v, ok := unpackedData["amount"].(*big.Int); ok {
			decoded.Amount = v
		}
	case "Initialized":
		// Note: go-ethereum UnpackLogIndexedArg might return uint8 for version if it's uint8 in ABI
		// Adjust type assertion if necessary based on actual ABI definition.
		if v, ok := unpackedData["version"].(*big.Int); ok { // Assuming version is big.Int
			decoded.Version = v
		} else if vUint8, okUint8 := unpackedData["version"].(uint8); okUint8 {
			// Handle case if version is uint8
			decoded.Version = big.NewInt(int64(vUint8))
		}
	case "InvalidRewardClaimAmount":
		if v, ok := unpackedData["projectId"].(*big.Int); ok {
			decoded.ProjectId = v
		}
		if v, ok := unpackedData["requestEpochNumber"].(*big.Int); ok {
			decoded.RequestEpochNumber = v
		}
		if v, ok := unpackedData["amount"].(*big.Int); ok {
			decoded.Amount = v
		}
		if v, ok := unpackedData["diffAmmount"].(*big.Int); ok {
			decoded.DiffAmmount = v
		} // Typo in event name? "diffAmount"?
	case "ProjectAdded":
		if v, ok := unpackedData["projectId"].(*big.Int); ok {
			decoded.ProjectId = v
		}
		if v, ok := unpackedData["owner"].(common.Address); ok {
			decoded.Owner = &v
		}
		if v, ok := unpackedData["rewardsRecipient"].(common.Address); ok {
			decoded.RewardsRecipient = &v
		}
		if v, ok := unpackedData["metadataUri"].(string); ok {
			decoded.MetadataUri = &v
		}
		if v, ok := unpackedData["activeFromEpoch"].(*big.Int); ok {
			decoded.ActiveFromEpoch = v
		}
		// Handle slice of addresses - UnpackIntoMap might return []interface{} or specific type
		if v, ok := unpackedData["contracts"].([]common.Address); ok {
			contractsCopy := make([]common.Address, len(v))
			copy(contractsCopy, v)
			decoded.Contracts = &contractsCopy
		} else if vSlice, okSlice := unpackedData["contracts"].([]interface{}); okSlice {
			// Handle case where it's unpacked as []interface{}
			contracts := make([]common.Address, 0, len(vSlice))
			valid := true
			for _, item := range vSlice {
				if addr, addrOk := item.(common.Address); addrOk {
					contracts = append(contracts, addr)
				} else {
					valid = false
					break
				}
			}
			if valid {
				decoded.Contracts = &contracts
			} else {
				log.Warnf(ctx, "Decoder: Could not cast 'contracts' slice elements to common.Address for ProjectAdded event (log %s:%d)", logEntry.TxHash.Hex(), logEntry.Index)
			}
		}
	case "ProjectContractAdded", "ProjectContractRemoved":
		if v, ok := unpackedData["projectId"].(*big.Int); ok {
			decoded.ProjectId = v
		}
		if v, ok := unpackedData["contractAddress"].(common.Address); ok {
			decoded.ContractAddress = &v
		}
	case "ProjectEnabled":
		if v, ok := unpackedData["projectId"].(*big.Int); ok {
			decoded.ProjectId = v
		}
		if v, ok := unpackedData["enabledOnEpochNumber"].(*big.Int); ok {
			decoded.EnabledOnEpochNumber = v
		}
	case "ProjectMetadataUriUpdated":
		if v, ok := unpackedData["projectId"].(*big.Int); ok {
			decoded.ProjectId = v
		}
		if v, ok := unpackedData["metadataUri"].(string); ok {
			decoded.MetadataUri = &v
		}
	case "ProjectOwnerUpdated":
		if v, ok := unpackedData["projectId"].(*big.Int); ok {
			decoded.ProjectId = v
		}
		if v, ok := unpackedData["owner"].(common.Address); ok {
			decoded.Owner = &v
		}
	case "ProjectRewardsRecipientUpdated":
		if v, ok := unpackedData["projectId"].(*big.Int); ok {
			decoded.ProjectId = v
		}
		if v, ok := unpackedData["recipient"].(common.Address); ok {
			decoded.Recipient = &v
		}
	case "ProjectSuspended":
		if v, ok := unpackedData["projectId"].(*big.Int); ok {
			decoded.ProjectId = v
		}
		if v, ok := unpackedData["suspendedOnEpochNumber"].(*big.Int); ok {
			decoded.SuspendedOnEpochNumber = v
		}
	case "RewardClaimCanceled":
		if v, ok := unpackedData["projectId"].(*big.Int); ok {
			decoded.ProjectId = v
		}
		if v, ok := unpackedData["epochNumber"].(*big.Int); ok {
			decoded.EpochNumber = v
		}
	case "RewardClaimCompleted":
		if v, ok := unpackedData["projectId"].(*big.Int); ok {
			decoded.ProjectId = v
		}
		if v, ok := unpackedData["epochNumber"].(*big.Int); ok {
			decoded.EpochNumber = v
		}
		if v, ok := unpackedData["amount"].(*big.Int); ok {
			decoded.Amount = v
		}
	case "RewardClaimConfirmationsLimitUpdated", "RewardClaimEpochsLimitUpdated":
		if v, ok := unpackedData["limit"].(*big.Int); ok {
			decoded.Limit = v
		}
	case "RewardClaimRequested":
		if v, ok := unpackedData["projectId"].(*big.Int); ok {
			decoded.ProjectId = v
		}
		if v, ok := unpackedData["requestEpochNumber"].(*big.Int); ok {
			decoded.RequestEpochNumber = v
		}
	case "RoleAdminChanged":
		// UnpackLogIndexedArg might return [32]byte for bytes32
		if v, ok := unpackedData["role"].([32]byte); ok {
			h := common.BytesToHash(v[:])
			decoded.Role = &h
		}
		if v, ok := unpackedData["previousAdminRole"].([32]byte); ok {
			h := common.BytesToHash(v[:])
			decoded.PreviousAdminRole = &h
		}
		if v, ok := unpackedData["newAdminRole"].([32]byte); ok {
			h := common.BytesToHash(v[:])
			decoded.NewAdminRole = &h
		}
	case "RoleGranted", "RoleRevoked":
		if v, ok := unpackedData["role"].([32]byte); ok {
			h := common.BytesToHash(v[:])
			decoded.Role = &h
		}
		if v, ok := unpackedData["account"].(common.Address); ok {
			decoded.Account = &v
		}
		if v, ok := unpackedData["sender"].(common.Address); ok {
			decoded.Sender = &v
		}
	case "SfcAddressUpdated":
		if v, ok := unpackedData["sfcAddress"].(common.Address); ok {
			decoded.SfcAddress = &v
		}
	case "SfcFeeUpdated":
		if v, ok := unpackedData["fee"].(*big.Int); ok {
			decoded.Fee = v
		}
	case "Upgraded":
		if v, ok := unpackedData["implementation"].(common.Address); ok {
			decoded.Implementation = &v
		}
	case "ProjectCreated": // Assuming this event exists based on user input
		// Assuming ProjectId was typo 'epoch' in user input struct
		if v, ok := unpackedData["projectId"].(*big.Int); ok {
			decoded.ProjectId = v
		}
		if v, ok := unpackedData["amount"].(*big.Int); ok {
			decoded.Amount = v
		}
	default:
		log.Warnf(ctx, "Decoder: Event '%s' unpacked (log %s:%d), but no specific mapping logic implemented.", decoded.EventName, logEntry.TxHash.Hex(), logEntry.Index)
	}

	log.Debugf(ctx, "Decoder: Decoded event '%s' from log %s:%d", decoded.EventName, logEntry.TxHash.Hex(), logEntry.Index)
	// stats.Count(ctx, fmt.Sprintf("event_%s_decoded", decoded.EventName), 1)
	log.Debugf(ctx, "Emiting event '%s'", decoded.EventName)
	emit(decoded)
	return nil
}

// --- Key Extractor DoFn ---
type extractKeyEventFn struct{}

// ProcessElement extracts a unique key (TxHash:LogIndex) and the event itself.
func (fn *extractKeyEventFn) ProcessElement(event chain.DecodedEvent, emit func(string, chain.DecodedEvent)) {
	key := fmt.Sprintf("%s:%d", event.Log.TxHash.Hex(), event.Log.Index)
	emit(key, event)
}

// --- Filter Duplicates DoFn ---
type filterDuplicatesFn struct{}

// ProcessElement receives an iterator for events with the same key.
// Emits the first to main output, subsequent ones to duplicate output.
func (fn *filterDuplicatesFn) ProcessElement(ctx context.Context, key string, events func(*chain.DecodedEvent) bool, emitUnique func(chain.DecodedEvent), emitDuplicate func(chain.DecodedEvent)) {
	var event chain.DecodedEvent
	isFirst := true
	count := 0
	for events(&event) {
		count++
		if isFirst {
			emitUnique(event)
			isFirst = false
		} else {
			log.Debugf(ctx, "Duplicates: Duplicate detected for key %s (occurrence %d)", key, count)
			emitDuplicate(event)
		}
	}
	// if count > 1 {
	// 	stats.Count(ctx, "duplicates_found", int64(count-1))
	// }
}

// --- Convert to BigQuery Record DoFns ---
type convertToBQRecordFn struct{}

// ProcessElement converts a DecodedEvent to a BQEventRecord.
func (fn *convertToBQRecordFn) ProcessElement(ctx context.Context, event chain.DecodedEvent, emit func(bigquery.BQEventRecord)) {
	record := bigquery.BQEventRecord{
		// Map all fields from DecodedEvent using helper functions for safety
		Amount:      chain.SafeBigIntString(event.Amount),
		ProjectId:   chain.SafeBigIntString(event.ProjectId),
		EpochNumber: chain.SafeBigIntString(event.EpochNumber),

		Funder: chain.SafeAddressHex(event.Funder),

		Recipient: chain.SafeAddressHex(event.Recipient),

		Version: chain.SafeBigIntString(event.Version),

		RequestEpochNumber: chain.SafeBigIntString(event.RequestEpochNumber),
		DiffAmmount:        chain.SafeBigIntString(event.DiffAmmount), // Typo?

		Owner: chain.SafeAddressHex(event.Owner),

		RewardsRecipient: chain.SafeAddressHex(event.RewardsRecipient),
		MetadataUri:      chain.SafeString(event.MetadataUri),
		ActiveFromEpoch:  chain.SafeBigIntString(event.ActiveFromEpoch),
		Contracts:        chain.SafeAddressSliceHex(event.Contracts), // Will be REPEATED STRING

		ContractAddress: chain.SafeAddressHex(event.ContractAddress),

		EnabledOnEpochNumber: chain.SafeBigIntString(event.EnabledOnEpochNumber),

		SuspendedOnEpochNumber: chain.SafeBigIntString(event.SuspendedOnEpochNumber),

		Limit: chain.SafeBigIntString(event.Limit),

		Role:              chain.SafeHashHex(event.Role),
		PreviousAdminRole: chain.SafeHashHex(event.PreviousAdminRole),
		NewAdminRole:      chain.SafeHashHex(event.NewAdminRole),

		Account: chain.SafeAddressHex(event.Account),
		Sender:  chain.SafeAddressHex(event.Sender),

		SfcAddress: chain.SafeAddressHex(event.SfcAddress),

		Implementation: chain.SafeAddressHex(event.Implementation),

		Fee: chain.SafeBigIntString(event.Fee),

		// Metadata
		EventName:                event.EventName,
		EmittedByContractAddress: event.Log.Address.Hex(), // Get directly from log
		BlockNumber:              int64(event.Log.BlockNumber),
		BlockHash:                event.Log.BlockHash.Hex(),
		TxHash:                   event.Log.TxHash.Hex(),
		TxIndex:                  int(event.Log.TxIndex),
		LogIndex:                 int(event.Log.Index),
		Removed:                  event.Log.Removed,
		PipelineTime:             time.Now().UTC(),
	}

	emit(record)
}

type convertToBQDuplicateRecordFn struct{}

func (fn *convertToBQDuplicateRecordFn) ProcessElement(ctx context.Context, event chain.DecodedEvent, emit func(bigquery.BQDuplicateRecord)) {
	// Create the base record first using similar logic to convertToBQRecordFn
	baseRecord := bigquery.BQEventRecord{
		Amount:                 chain.SafeBigIntString(event.Amount),
		ProjectId:              chain.SafeBigIntString(event.ProjectId),
		EpochNumber:            chain.SafeBigIntString(event.EpochNumber),
		Funder:                 chain.SafeAddressHex(event.Funder),
		Recipient:              chain.SafeAddressHex(event.Recipient),
		Version:                chain.SafeBigIntString(event.Version),
		RequestEpochNumber:     chain.SafeBigIntString(event.RequestEpochNumber),
		DiffAmmount:            chain.SafeBigIntString(event.DiffAmmount),
		Owner:                  chain.SafeAddressHex(event.Owner),
		RewardsRecipient:       chain.SafeAddressHex(event.RewardsRecipient),
		MetadataUri:            chain.SafeString(event.MetadataUri),
		ActiveFromEpoch:        chain.SafeBigIntString(event.ActiveFromEpoch),
		Contracts:              chain.SafeAddressSliceHex(event.Contracts),
		ContractAddress:        chain.SafeAddressHex(event.ContractAddress),
		EnabledOnEpochNumber:   chain.SafeBigIntString(event.EnabledOnEpochNumber),
		SuspendedOnEpochNumber: chain.SafeBigIntString(event.SuspendedOnEpochNumber),
		Limit:                  chain.SafeBigIntString(event.Limit),
		Role:                   chain.SafeHashHex(event.Role),
		PreviousAdminRole:      chain.SafeHashHex(event.PreviousAdminRole),
		NewAdminRole:           chain.SafeHashHex(event.NewAdminRole),
		Account:                chain.SafeAddressHex(event.Account),
		Sender:                 chain.SafeAddressHex(event.Sender),
		SfcAddress:             chain.SafeAddressHex(event.SfcAddress),
		Implementation:         chain.SafeAddressHex(event.Implementation),
		Fee:                    chain.SafeBigIntString(event.Fee),
		// Metadata
		EventName:                event.EventName,
		EmittedByContractAddress: event.Log.Address.Hex(),
		BlockNumber:              int64(event.Log.BlockNumber),
		BlockHash:                event.Log.BlockHash.Hex(),
		TxHash:                   event.Log.TxHash.Hex(),
		TxIndex:                  int(event.Log.TxIndex),
		LogIndex:                 int(event.Log.Index),
		Removed:                  event.Log.Removed,
		PipelineTime:             time.Now().UTC(), // Consider if this should be the original processing time
	}

	duplicateRecord := bigquery.BQDuplicateRecord{
		BQEventRecord:          baseRecord,
		DuplicateDetectionTime: time.Now().UTC(), // Time duplicate was identified
	}
	emit(duplicateRecord)
}

func init() {
	// Register DoFns in this package
	register.DoFn3x1[context.Context, types.Log, func(chain.DecodedEvent), error]((*decodeLogFn)(nil))
	register.DoFn2x0[chain.DecodedEvent, func(string, chain.DecodedEvent)]((*extractKeyEventFn)(nil))
	register.DoFn5x0[context.Context, string, func(*chain.DecodedEvent) bool, func(chain.DecodedEvent), func(chain.DecodedEvent)]((*filterDuplicatesFn)(nil))
	register.DoFn3x0[context.Context, chain.DecodedEvent, func(bigquery.BQEventRecord)]((*convertToBQRecordFn)(nil))
	register.DoFn3x0[context.Context, chain.DecodedEvent, func(bigquery.BQDuplicateRecord)]((*convertToBQDuplicateRecordFn)(nil))

	register.Emitter1[chain.DecodedEvent]()
	register.Emitter1[bigquery.BQEventRecord]()
	register.Emitter1[bigquery.BQDuplicateRecord]()

	// Register time.Time encoder/decoder if not done elsewhere
	// register.RegisterStructEncoder(reflect.TypeOf(time.Time{}), func(t time.Time) ([]byte, error) {
	// 	return t.MarshalBinary()
	// }, func(b []byte) (time.Time, error) {
	// 	var t time.Time
	// 	err := t.UnmarshalBinary(b)
	// 	return t, err
	// })
}
