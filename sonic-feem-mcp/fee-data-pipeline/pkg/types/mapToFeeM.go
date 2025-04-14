package types

// import (
// 	"fmt"

// 	"github.com/ethereum/go-ethereum/accounts/abi"
// 	"github.com/ethereum/go-ethereum/core/types"
// )

// // MapLogToEvent attempts to map a types.Log to its corresponding event struct
// // based on the provided ABI. It returns the populated struct as an interface{},
// // the name of the event found, or an error if mapping fails.
// func MapLogToEvent(contractABI abi.ABI, log types.Log) (interface{}, string, error) {
// 	if len(log.Topics) == 0 {
// 		return nil, "", fmt.Errorf("log has no topics, cannot identify event")
// 	}

// 	// The first topic is the event signature hash
// 	eventSigHash := log.Topics[0]

// 	// Find the event definition in the ABI using the signature hash
// 	event, err := contractABI.EventByID(eventSigHash)
// 	if err != nil {
// 		return nil, "", fmt.Errorf("event not found in ABI for signature %s: %w", eventSigHash.Hex(), err)
// 	}

// 	// Use the event name found in the ABI to determine the target struct type
// 	// and unpack the log data into it.
// 	var eventData interface{}
// 	eventName := event.Name // Keep track of the event name

// 	logAsBytes, err := log.MarshalJSON()
// 	if err != nil {
// 		return nil, "", fmt.Errorf("failed to marshal log to JSON: %w", err)
// 	}
// 	switch eventName {
// 	case "FundsAdded":
// 		var data FundsAdded
// 		err = contractABI.UnpackIntoInterface(&data, eventName, logAsBytes) // .UnpackLog(&data, eventName, log) .UnpackLog(&data, eventName, log)
// 		eventData = data
// 	case "FundsWithdrawn":
// 		var data FundsWithdrawn
// 		err = contractABI.UnpackIntoInterface(&data, eventName, logAsBytes)
// 		eventData = data
// 	case "Initialized":
// 		var data Initialized
// 		err = contractABI.UnpackIntoInterface(&data, eventName, logAsBytes)
// 		eventData = data
// 	case "InvalidRewardClaimAmount":
// 		var data InvalidRewardClaimAmount
// 		err = contractABI.UnpackIntoInterface(&data, eventName, logAsBytes)
// 		eventData = data
// 	case "ProjectAdded":
// 		var data ProjectAdded
// 		err = contractABI.UnpackIntoInterface(&data, eventName, logAsBytes)
// 		eventData = data
// 	case "ProjectContractAdded":
// 		var data ProjectContractAdded
// 		err = contractABI.UnpackIntoInterface(&data, eventName, logAsBytes)
// 		eventData = data
// 	case "ProjectContractRemoved":
// 		var data ProjectContractRemoved
// 		err = contractABI.UnpackIntoInterface(&data, eventName, logAsBytes)
// 		eventData = data
// 	case "ProjectEnabled":
// 		var data ProjectEnabled
// 		err = contractABI.UnpackIntoInterface(&data, eventName, logAsBytes)
// 		eventData = data
// 	case "ProjectMetadataUriUpdated":
// 		var data ProjectMetadataUriUpdated
// 		err = contractABI.UnpackIntoInterface(&data, eventName, logAsBytes)
// 		eventData = data
// 	case "ProjectOwnerUpdated":
// 		var data ProjectOwnerUpdated
// 		err = contractABI.UnpackIntoInterface(&data, eventName, logAsBytes)
// 		eventData = data
// 	case "ProjectRewardsRecipientUpdated":
// 		var data ProjectRewardsRecipientUpdated
// 		err = contractABI.UnpackIntoInterface(&data, eventName, logAsBytes)
// 		eventData = data
// 	case "ProjectSuspended":
// 		var data ProjectSuspended
// 		err = contractABI.UnpackIntoInterface(&data, eventName, logAsBytes)
// 		eventData = data
// 	case "RewardClaimCanceled":
// 		var data RewardClaimCanceled
// 		err = contractABI.UnpackIntoInterface(&data, eventName, logAsBytes)
// 		eventData = data
// 	case "RewardClaimCompleted":
// 		var data RewardClaimCompleted
// 		err = contractABI.UnpackIntoInterface(&data, eventName, logAsBytes)
// 		eventData = data
// 	case "RewardClaimConfirmationsLimitUpdated":
// 		var data RewardClaimConfirmationsLimitUpdated
// 		err = contractABI.UnpackIntoInterface(&data, eventName, logAsBytes)
// 		eventData = data
// 	case "RewardClaimEpochsLimitUpdated":
// 		var data RewardClaimEpochsLimitUpdated
// 		err = contractABI.UnpackIntoInterface(&data, eventName, logAsBytes)
// 		eventData = data
// 	case "RewardClaimRequested":
// 		var data RewardClaimRequested
// 		err = contractABI.UnpackIntoInterface(&data, eventName, logAsBytes)
// 		eventData = data
// 	case "RoleAdminChanged":
// 		var data RoleAdminChanged
// 		err = contractABI.UnpackIntoInterface(&data, eventName, logAsBytes)
// 		eventData = data
// 	case "RoleGranted":
// 		var data RoleGranted
// 		err = contractABI.UnpackIntoInterface(&data, eventName, logAsBytes)
// 		eventData = data
// 	case "RoleRevoked":
// 		var data RoleRevoked
// 		err = contractABI.UnpackIntoInterface(&data, eventName, logAsBytes)
// 		eventData = data
// 	case "SfcAddressUpdated":
// 		var data SfcAddressUpdated
// 		err = contractABI.UnpackIntoInterface(&data, eventName, logAsBytes)
// 		eventData = data
// 	case "Upgraded":
// 		var data Upgraded
// 		err = contractABI.UnpackIntoInterface(&data, eventName, logAsBytes)
// 		eventData = data
// 	default:
// 		// This case should technically not be reached if EventByID succeeded
// 		// but acts as a safeguard.
// 		return nil, eventName, fmt.Errorf("unhandled event type in ABI: %s", eventName)
// 	}

// 	// Check for unpacking errors
// 	if err != nil {
// 		return nil, eventName, fmt.Errorf("error unpacking log for event %s: %w", eventName, err)
// 	}

// 	// Return the populated struct (as interface{}), the event name, and no error
// 	return eventData, eventName, nil
// }

// // Example Usage (requires the ABI JSON string):
// // func main() {
// // 	// 1. Load the ABI (replace `abiJSON` with the actual ABI string)
// // 	abiJSON := `[ ... your ABI JSON string ... ]` // Load your ABI string here
// // 	contractABI, err := abi.JSON(strings.NewReader(abiJSON))
// // 	if err != nil {
// // 		panic(fmt.Sprintf("Failed to parse ABI: %v", err))
// // 	}

// // 	// 2. Assume you have received a log entry (e.g., from an Ethereum client subscription)
// // 	//    This is a placeholder example log structure.
// // 	exampleLog := types.Log{
// // 		Address: common.HexToAddress("0xYourContractAddress"),
// // 		Topics: []common.Hash{
// // 			common.HexToHash("0xEventSignatureHash"), // e.g., FundsAdded signature hash
// // 			common.HexToHash("0xIndexedParam1"),      // e.g., funder address padded
// // 		},
// // 		Data: []byte{ /* ... non-indexed data bytes ... */ },
// // 		// BlockNumber, TxHash etc. are also part of the log
// // 	}

// // 	// 3. Map the log to an event struct
// // 	eventData, eventName, err := MapLogToEvent(contractABI, exampleLog)
// // 	if err != nil {
// // 		fmt.Printf("Failed to map log: %v\n", err)
// // 		// Handle error, maybe log wasn't from this contract or was malformed
// // 		return
// // 	}

// // 	// 4. Use a type assertion or type switch to work with the specific event data
// // 	fmt.Printf("Successfully mapped event: %s\n", eventName)
// // 	switch data := eventData.(type) {
// // 	case FundsAdded:
// // 		fmt.Printf("Funds Added - Funder: %s, Amount: %s\n", data.Funder.Hex(), data.Amount.String())
// // 	case ProjectAdded:
// // 		fmt.Printf("Project Added - ID: %s, Owner: %s\n", data.ProjectId.String(), data.Owner.Hex())
// // 		// ... access other fields of ProjectAdded
// // 	// Add cases for all other event types...
// // 	default:
// // 		fmt.Println("Log mapped to an unknown event struct type (this shouldn't happen)")
// // 	}
// // }
