package pipeline

import (

	// Import strings for topic parsing

	"context"
	"encoding/json"
	"fmt"
	"math/big"
	"reflect"

	"cloud.google.com/go/bigquery"
	"github.com/apache/beam/sdks/v2/go/pkg/beam"
	"github.com/apache/beam/sdks/v2/go/pkg/beam/io/avroio"
	"github.com/apache/beam/sdks/v2/go/pkg/beam/io/bigqueryio"
	"github.com/apache/beam/sdks/v2/go/pkg/beam/log"
	"github.com/apache/beam/sdks/v2/go/pkg/beam/x/debug"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/swaggest/jsonschema-go"

	// "github.com/finiteloopme/dcentral-dev/sonic-feem-mcp/fee-data-pipeline/pkg/bigquery" // Remove bigquery import
	"github.com/finiteloopme/dcentral-dev/sonic-feem-mcp/fee-data-pipeline/pkg/chain"
	"github.com/finiteloopme/dcentral-dev/sonic-feem-mcp/fee-data-pipeline/pkg/config"
)

// Build constructs the Beam pipeline graph.
func Build(s beam.Scope, cfg *config.Config, abiString string, parsedABI *abi.ABI) {
	ctx := context.Background()
	reflector := jsonschema.Reflector{}
	schema, err := reflector.Reflect(chain.DecodedEvent{})
	if err != nil {
		log.Errorf(ctx, "Error reflecting schema: %v", err)
		return
	}

	schemaToString, err := json.Marshal(schema)
	if err != nil {
		log.Errorf(ctx, "Error marshaling schema: %v", err)
		return
	}
	// log.Infof(ctx, "Schema: %v", string(schemaToString))

	s = s.Scope("SonicEventPipeline") // Add scope for clarity in UI

	// 1. Start with an impulse to trigger the source DoFn
	impulse := beam.Impulse(s)

	// 2. Read logs from Ethereum WebSocket (Custom Source)
	rawLogs := beam.ParDo(s.Scope("ReadLogs"), chain.NewEthLogStreamFn(cfg.WebsocketURL, cfg.ContractAddress), impulse)

	debug.Printf(s, "Logs: %v", rawLogs)
	// 3. Decode logs into events
	feemEvents := beam.ParDo(s.Scope("EncodeEvent"), func(ethLog types.Log, emit func(string)) {
		log.Infof(ctx, "In Dofn Log: %v", ethLog)
		if len(ethLog.Topics) == 0 {
			log.Warnf(ctx, "Decoder: Log entry %s:%d has no topics, cannot decode event.", ethLog.TxHash.Hex(), ethLog.Index)

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

	debug.Printf(s, "Events: %v", feemEvents)
	// avroio.Write(s, "/tmp/temp.avro", string(schemaToString), feemEvents)
	avroio.Write(s, "gs://kunal-scratch/sonic-raw-events/raw-logs.avro", string(schemaToString), feemEvents)
	debug.Printf(s, "Write to BQ: %v", feemEvents)
	e := beam.ParDo(s, func(decodedEventInString string, emit func(chain.DecodedEvent)) {
		decodedEvent := chain.DecodedEvent{}
		err := json.Unmarshal([]byte(decodedEventInString), &decodedEvent)
		if err != nil {
			log.Errorf(ctx, "Error unmarshaling decoded event: %v", err)
			return
		}
		emit(decodedEvent)
	}, feemEvents)
	debug.Printf(s, "Decoded events: %v", e)
	bigqueryio.Write(s,
		"kunal-scratchpad",
		fmt.Sprintf("%s:%s.%s", "kunal-scratch", "sonic_feem", "feem_events"), //"kunal-scratch.sonic_feem.feem_events",
		e,
		bigqueryio.WithCreateDisposition(bigquery.CreateIfNeeded),
	)
}

// MapLogToEvent attempts to map a types.Log to its corresponding event struct
// based on the provided ABI. It returns the populated struct as a DecodedEvent,
// or an error if mapping fails.
func MapLogToEvent(contractABI *abi.ABI, logEntry types.Log) (*chain.DecodedEvent, error) {
	if len(logEntry.Topics) == 0 {
		return &chain.DecodedEvent{}, fmt.Errorf("log has no topics, cannot identify event")
	}

	eventSig := logEntry.Topics[0] // First topic is usually the event signature hash

	event, err := contractABI.EventByID(eventSig)
	if err != nil {
		err := fmt.Errorf("Decoder: Log %s:%d: No matching event found in ABI for signature %s", logEntry.TxHash.Hex(), logEntry.Index, eventSig.Hex())
		return nil, err // Skip logs for events not in the ABI
	}

	// Found matching event in ABI
	rawBytes, err := logEntry.MarshalJSON()
	if err != nil {
		err := fmt.Errorf("Decoder: Failed to marshal raw log Entry for event '%s' (log %s:%d): %v", event.Name, logEntry.TxHash.Hex(), logEntry.Index, err)
		return nil, err
	}
	decoded := chain.DecodedEvent{
		Log:       string(rawBytes),
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
			decoded.Funder = v.String()
		}
		if v, ok := unpackedData["amount"].(*big.Int); ok {
			decoded.Amount = v
		}
	case "FundsWithdrawn":
		if v, ok := unpackedData["recipient"].(common.Address); ok {
			decoded.Recipient = v.String()
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
			decoded.Owner = v.String()
		}
		if v, ok := unpackedData["rewardsRecipient"].(common.Address); ok {
			decoded.RewardsRecipient = v.String()
		}
		if v, ok := unpackedData["metadataUri"].(string); ok {
			decoded.MetadataUri = v
		}
		if v, ok := unpackedData["activeFromEpoch"].(*big.Int); ok {
			decoded.ActiveFromEpoch = v
		}
		if v, ok := unpackedData["contracts"].([]common.Address); ok {
			contractsCopy := make([]string, len(v))
			//copy(contractsCopy, v)
			for i, addr := range v {
				contractsCopy[i] = addr.String()
			}
			decoded.Contracts = contractsCopy
		} else if vSlice, okSlice := unpackedData["contracts"].([]interface{}); okSlice {
			contracts := make([]string, 0, len(vSlice))
			valid := true
			for _, item := range vSlice {
				if addr, addrOk := item.(common.Address); addrOk {
					contracts = append(contracts, addr.String())
				} else {
					valid = false
					break
				}
			}
			if valid {
				decoded.Contracts = contracts
			} else {
				return nil, fmt.Errorf("Decoder: Could not cast 'contracts' slice elements to common.Address for ProjectAdded event (log %s:%d)", logEntry.TxHash.Hex(), logEntry.Index)
			}
		}
	case "ProjectContractAdded", "ProjectContractRemoved":
		if v, ok := unpackedData["projectId"].(*big.Int); ok {
			decoded.ProjectId = v
		}
		if v, ok := unpackedData["contractAddress"].(common.Address); ok {
			decoded.ContractAddress = v.String()
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
			decoded.MetadataUri = v
		}
	case "ProjectOwnerUpdated":
		if v, ok := unpackedData["projectId"].(*big.Int); ok {
			decoded.ProjectId = v
		}
		if v, ok := unpackedData["owner"].(common.Address); ok {
			decoded.Owner = v.String()
		}
	case "ProjectRewardsRecipientUpdated":
		if v, ok := unpackedData["projectId"].(*big.Int); ok {
			decoded.ProjectId = v
		}
		if v, ok := unpackedData["recipient"].(common.Address); ok {
			decoded.Recipient = v.String()
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
			decoded.Role = h.String()
		}
		if v, ok := unpackedData["previousAdminRole"].([32]byte); ok {
			h := common.BytesToHash(v[:])
			decoded.PreviousAdminRole = h.String()
		}
		if v, ok := unpackedData["newAdminRole"].([32]byte); ok {
			h := common.BytesToHash(v[:])
			decoded.NewAdminRole = h.String()
		}
	case "RoleGranted", "RoleRevoked":
		if v, ok := unpackedData["role"].([32]byte); ok {
			h := common.BytesToHash(v[:])
			decoded.Role = h.String()
		}
		if v, ok := unpackedData["account"].(common.Address); ok {
			decoded.Account = v.String()
		}
		if v, ok := unpackedData["sender"].(common.Address); ok {
			decoded.Sender = v.String()
		}
	case "SfcAddressUpdated":
		if v, ok := unpackedData["sfcAddress"].(common.Address); ok {
			decoded.SfcAddress = v.String()
		}
	case "SfcFeeUpdated":
		if v, ok := unpackedData["fee"].(*big.Int); ok {
			decoded.Fee = v
		}
	case "Upgraded":
		if v, ok := unpackedData["implementation"].(common.Address); ok {
			decoded.Implementation = v.String()
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
	// // START OF CHANGES
	// // The first topic is the event signature hash
	// eventSigHash := log.Topics[0]

	// // Find the event definition in the ABI using the signature hash
	// event, err := contractABI.EventByID(eventSigHash)
	// if err != nil {
	// 	return chain.DecodedEvent{}, fmt.Errorf("event not found in ABI for signature %s: %w", eventSigHash.Hex(), err)
	// }

	// // Create a new map to hold the unpacked data
	// unpackedData := make(map[string]interface{})

	// // Unpack log data into the map
	// err = contractABI.UnpackIntoMap(unpackedData, event.Name, log.Data)
	// if err != nil {
	// 	return chain.DecodedEvent{}, fmt.Errorf("error unpacking log for event %s: %w", event.Name, err)
	// }
	// jsonData, err := json.Marshal(unpackedData)
	// if err != nil {
	// 	return chain.DecodedEvent{}, fmt.Errorf("error marshaling unpacked data in JSON: %w", err)
	// }
	// var eventData chain.DecodedEvent
	// err = json.Unmarshal(jsonData, &eventData)
	// if err != nil {
	// 	return chain.DecodedEvent{}, fmt.Errorf("error unmarshaling JSON into DecodedEvent: %w", err)
	// }
	// eventData.Log = log
	// eventData.EventName = event.Name
	// // DONE CHANGES

	// Create a new DecodedEvent and set its fields based on the unpacked data
	// eventData := chain.DecodedEvent{
	// 	Log:       log,
	// 	EventName: event.Name,
	// 	// Set other fields based on the unpacked data
	// 	// For example:
	// 	// Amount:      unpackedData["amount"].(*big.Int),
	// 	// ProjectId:   unpackedData["projectId"].(*big.Int),
	// 	// ...
	// }

	// return eventData, nil
}

func init() {
	beam.RegisterType(reflect.TypeOf(chain.DecodedEvent{}))
}
