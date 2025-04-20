package pipeline

import (

	// Import strings for topic parsing

	"context"
	"encoding/json"
	"fmt"
	"math/big"
	"reflect"

	"github.com/apache/beam/sdks/v2/go/pkg/beam"
	"github.com/apache/beam/sdks/v2/go/pkg/beam/io/bigqueryio"
	"github.com/apache/beam/sdks/v2/go/pkg/beam/log"
	"github.com/apache/beam/sdks/v2/go/pkg/beam/x/debug"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"

	"github.com/finiteloopme/dcentral-dev/sonic-feem-mcp/fee-data-pipeline/pkg/config"
	t "github.com/finiteloopme/dcentral-dev/sonic-feem-mcp/fee-data-pipeline/pkg/types"
)

// Build constructs the Beam pipeline graph.
func Build(s beam.Scope, cfg *config.Config, abiString string, parsedABI *abi.ABI) {
	s = s.Scope("SonicEventPipeline") // Add scope for clarity in UI
	ctx := context.Background()

	// 1. Read logs from Src BQ
	selectLogs := fmt.Sprintf(
		`SELECT * FROM %s.%s.%s WHERE block_number > %d ORDER BY block_number DESC LIMIT %d`,
		cfg.SrcBQProject,
		cfg.SrcBQDataset,
		cfg.SrcBQTable,
		cfg.StartFromBlock,
		1)
	rawLogs := bigqueryio.Query(s, cfg.SrcBQProject, selectLogs, reflect.TypeOf(t.BQLog{}), bigqueryio.UseStandardSQL())
	// debug.Printf(s, "Logs: %v", rawLogs)

	// 3. Decode logs into events
	feemEvents := beam.ParDo(s.Scope("EncodeEvent"), func(ethLog t.BQLog, emit func(string)) {
		log.Infof(ctx, "In EncodeEvent for Block Hash: %s, Block Number: %d, Tx Hash: %s, Topics: %v", ethLog.BlockHash, ethLog.BlockNumber, ethLog.TransactionHash, ethLog.Topics)
		if len(ethLog.Topics) == 0 {
			log.Warnf(ctx, "Decoder: Log entry %s:%d has no topics, cannot decode event.", ethLog.TransactionHash, ethLog.LogIndex)

			return // Skip logs without topics
		}

		decodedEvent, _ := MapLogToEvent(parsedABI, ethLog)
		jsonData, err := json.Marshal(decodedEvent)
		if err != nil {
			log.Errorf(ctx, "Error marshaling decoded event: %v", err)
			return
		}
		emit(string(jsonData))
		return
	}, rawLogs)

	debug.Printf(s, "Decoded Events: %v", feemEvents)
	// _ = schemaToString
	// avroio.Write(s, "/tmp/temp.avro", string(schemaToString), feemEvents)
	// avroio.Write(s, "gs://kunal-scratch/sonic-raw-events/raw-logs.avro", string(schemaToString), feemEvents)
	// debug.Printf(s, "Write to BQ: %v", feemEvents)
	// e := beam.ParDo(s, func(decodedEventInString string, emit func(chain.DecodedEvent)) {
	// 	decodedEvent := chain.DecodedEvent{}
	// 	err := json.Unmarshal([]byte(decodedEventInString), &decodedEvent)
	// 	if err != nil {
	// 		log.Errorf(ctx, "Error unmarshaling decoded event: %v", err)
	// 		return
	// 	}
	// 	emit(decodedEvent)
	// }, feemEvents)
	// debug.Printf(s, "Decoded events: %v", e)
	// bigqueryio.Write(s,
	// 	"kunal-scratchpad",
	// 	fmt.Sprintf("%s:%s.%s", "kunal-scratch", "sonic_feem", "feem_events"), //"kunal-scratch.sonic_feem.feem_events",
	// 	e,
	// 	bigqueryio.WithCreateDisposition(bigquery.CreateIfNeeded),
	// )
}

// MapLogToEvent attempts to map a types.Log to its corresponding event struct
// based on the provided ABI. It returns the populated struct as a DecodedEvent,
// or an error if mapping fails.
func MapLogToEvent(contractABI *abi.ABI, bqLog t.BQLog) (*t.DecodedEvent, error) {
	ctx := context.Background()
	for _, event := range contractABI.Events {
		log.Infof(ctx, "Event:: ID: %v, Name: %v, Hex: %v", event.ID, event.Name, event.ID.Hex())
	}
	logEntry := bqLog.ToEthLog() //&types.Log{}
	//json.Unmarshal([]byte(bqLog.Data.String()), logEntry)
	if len(logEntry.Topics) == 0 {
		err := fmt.Errorf("Decoder: Log %s:%d has no topics, cannot decode event.", logEntry.TxHash.Hex(), logEntry.Index)
		log.Warnf(ctx, err.Error())
		return nil, err
	}
	eventSig := logEntry.Topics[0] // First topic is usually the event signature hash

	event, err := contractABI.EventByID(eventSig)
	if err != nil {
		err := fmt.Errorf("Decoder: Log %s:%d: No matching event found in ABI for signature %s", logEntry.TxHash.Hex(), logEntry.Index, eventSig.Hex())
		log.Warnf(ctx, err.Error())
		return nil, err // Skip logs for events not in the ABI
	}
	log.Infof(context.Background(), "Event name: %v", event.Name)

	// Found matching event in ABI
	// rawBytes, err := logEntry.MarshalJSON()
	// if err != nil {
	// 	err := fmt.Errorf("Decoder: Failed to marshal raw log Entry for event '%s' (log %s:%d): %v", event.Name, logEntry.TxHash.Hex(), logEntry.Index, err)
	// 	return nil, err
	// }
	decoded := t.DecodedEvent{
		Log:       *logEntry, //string(rawBytes),
		EventName: event.Name,
	}

	// --- Unpack Event Data ---
	unpackedData := make(map[string]interface{})
	if !event.Anonymous {
		// Unpack non-indexed fields from log.Data
		err = contractABI.UnpackIntoMap(unpackedData, event.Name, logEntry.Data)
		if err != nil {
			err := fmt.Errorf("Decoder: Failed to unpack non-indexed data for event '%s' (log %s:%d): %v", event.Name, logEntry.TxHash.Hex(), logEntry.Index, err)
			return nil, err
		}
	}

	// Unpack indexed fields from log.Topics
	// Handle indexed topics
	topicIndex := 1 // Start from 1, as Topic[0] is the signature
	for _, arg := range event.Inputs {
		if arg.Indexed {
			if topicIndex >= len(logEntry.Topics) {
				err := fmt.Errorf("Decoder: Mismatched indexed topics for event '%s' (log %s:%d). Expected more topics.", event.Name, logEntry.TxHash.Hex(), logEntry.Index)
				// stats.Count(ctx, "decode_topic_mismatch", 1)
				return nil, err // Skip malformed events
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
	switch decoded.EventName {
	case "FundsAdded":
		if v, ok := unpackedData["funder"].(common.Address); ok {
			decoded.Funder = &v //v.String()
		}
		if v, ok := unpackedData["amount"].(*big.Int); ok {
			decoded.Amount = v
		}
	case "FundsWithdrawn":
		if v, ok := unpackedData["recipient"].(common.Address); ok {
			decoded.Recipient = &v //v.String()
		}
		if v, ok := unpackedData["amount"].(*big.Int); ok {
			decoded.Amount = v
		}
	case "Initialized":
		if v, ok := unpackedData["version"].(*big.Int); ok {
			decoded.Version = v
		} else if vUint8, okUint8 := unpackedData["version"].(uint8); okUint8 {
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
		}
	case "ProjectAdded":
		if v, ok := unpackedData["projectId"].(*big.Int); ok {
			decoded.ProjectId = v
		}
		if v, ok := unpackedData["owner"].(common.Address); ok {
			decoded.Owner = &v //v.String()
		}
		if v, ok := unpackedData["rewardsRecipient"].(common.Address); ok {
			decoded.RewardsRecipient = &v //v.String()
		}
		if v, ok := unpackedData["metadataUri"].(string); ok {
			decoded.MetadataUri = &v
		}
		if v, ok := unpackedData["activeFromEpoch"].(*big.Int); ok {
			decoded.ActiveFromEpoch = v
		}
		if v, ok := unpackedData["contracts"].([]common.Address); ok {
			contractsCopy := make([]common.Address, len(v))
			copy(contractsCopy, v)
			// for i, addr := range v {
			// 	contractsCopy[i] = addr.String()
			// }
			decoded.Contracts = &contractsCopy
		} else if vSlice, okSlice := unpackedData["contracts"].([]interface{}); okSlice {
			contracts := make([]common.Address, 0, len(vSlice))
			valid := true
			for _, item := range vSlice {
				if addr, addrOk := item.(common.Address); addrOk {
					contracts = append(contracts, addr) //addr.String())
				} else {
					valid = false
					break
				}
			}
			if valid {
				decoded.Contracts = &contracts
			} else {
				return nil, fmt.Errorf("Decoder: Could not cast 'contracts' slice elements to common.Address for ProjectAdded event (log %s:%d)", logEntry.TxHash.Hex(), logEntry.Index)
			}
		}
	case "ProjectContractAdded", "ProjectContractRemoved":
		if v, ok := unpackedData["projectId"].(*big.Int); ok {
			decoded.ProjectId = v
		}
		if v, ok := unpackedData["contractAddress"].(common.Address); ok {
			decoded.ContractAddress = &v //v.String()
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
			decoded.Owner = &v //v.String()
		}
	case "ProjectRewardsRecipientUpdated":
		if v, ok := unpackedData["projectId"].(*big.Int); ok {
			decoded.ProjectId = v
		}
		if v, ok := unpackedData["recipient"].(common.Address); ok {
			decoded.Recipient = &v //v.String()
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
		if v, ok := unpackedData["role"].([32]byte); ok {
			h := common.BytesToHash(v[:])
			decoded.Role = &h //h.String()
		}
		if v, ok := unpackedData["previousAdminRole"].([32]byte); ok {
			h := common.BytesToHash(v[:])
			decoded.PreviousAdminRole = &h //h.String()
		}
		if v, ok := unpackedData["newAdminRole"].([32]byte); ok {
			h := common.BytesToHash(v[:])
			decoded.NewAdminRole = &h //h.String()
		}
	case "RoleGranted", "RoleRevoked":
		if v, ok := unpackedData["role"].([32]byte); ok {
			h := common.BytesToHash(v[:])
			decoded.Role = &h //h.String()
		}
		if v, ok := unpackedData["account"].(common.Address); ok {
			decoded.Account = &v //v.String()
		}
		if v, ok := unpackedData["sender"].(common.Address); ok {
			decoded.Sender = &v //v.String()
		}
	case "SfcAddressUpdated":
		if v, ok := unpackedData["sfcAddress"].(common.Address); ok {
			decoded.SfcAddress = &v //v.String()
		}
	case "SfcFeeUpdated":
		if v, ok := unpackedData["fee"].(*big.Int); ok {
			decoded.Fee = v
		}
	case "Upgraded":
		if v, ok := unpackedData["implementation"].(common.Address); ok {
			decoded.Implementation = &v //v.String()
		}
	case "ProjectCreated":
		if v, ok := unpackedData["projectId"].(*big.Int); ok {
			decoded.ProjectId = v
		}
		if v, ok := unpackedData["amount"].(*big.Int); ok {
			decoded.Amount = v
		}
	default:
		return nil, fmt.Errorf("Decoder: Event '%s' unpacked (log %s:%d), but no specific mapping logic implemented.", decoded.EventName, logEntry.TxHash.Hex(), logEntry.Index)
	}
	return &decoded, nil
}

// 	// // START OF CHANGES
// 	// // The first topic is the event signature hash
// 	// eventSigHash := log.Topics[0]

// 	// // Find the event definition in the ABI using the signature hash
// 	// event, err := contractABI.EventByID(eventSigHash)
// 	// if err != nil {
// 	// 	return chain.DecodedEvent{}, fmt.Errorf("event not found in ABI for signature %s: %w", eventSigHash.Hex(), err)
// 	// }

// 	// // Create a new map to hold the unpacked data
// 	// unpackedData := make(map[string]interface{})

// 	// // Unpack log data into the map
// 	// err = contractABI.UnpackIntoMap(unpackedData, event.Name, log.Data)
// 	// if err != nil {
// 	// 	return chain.DecodedEvent{}, fmt.Errorf("error unpacking log for event %s: %w", event.Name, err)
// 	// }
// 	// jsonData, err := json.Marshal(unpackedData)
// 	// if err != nil {
// 	// 	return chain.DecodedEvent{}, fmt.Errorf("error marshaling unpacked data in JSON: %w", err)
// 	// }
// 	// var eventData chain.DecodedEvent
// 	// err = json.Unmarshal(jsonData, &eventData)
// 	// if err != nil {
// 	// 	return chain.DecodedEvent{}, fmt.Errorf("error unmarshaling JSON into DecodedEvent: %w", err)
// 	// }
// 	// eventData.Log = log
// 	// eventData.EventName = event.Name
// 	// // DONE CHANGES

// 	// Create a new DecodedEvent and set its fields based on the unpacked data
// 	// eventData := chain.DecodedEvent{
// 	// 	Log:       log,
// 	// 	EventName: event.Name,
// 	// 	// Set other fields based on the unpacked data
// 	// 	// For example:
// 	// 	// Amount:      unpackedData["amount"].(*big.Int),
// 	// 	// ProjectId:   unpackedData["projectId"].(*big.Int),
// 	// 	// ...
// 	// }

// 	// return eventData, nil
// }

func init() {
}
