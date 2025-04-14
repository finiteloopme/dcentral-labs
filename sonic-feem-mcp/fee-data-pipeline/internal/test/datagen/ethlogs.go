package main

import (
	"bytes"
	"crypto/rand"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"math/big"
	"net/http"
	"os"
	"reflect"
	"strings"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"golang.org/x/crypto/sha3"
)

// ABIURL is the location of the smart contract ABI definition.
const ABIURL = "https://raw.githubusercontent.com/finiteloopme/dcentral-labs/refs/heads/main/sonic-feem-mcp/fee-data-pipeline/feem-abi.json"

// PlaceholderContractAddress is used as the emitting contract address for generated logs.
var PlaceholderContractAddress = common.HexToAddress("0xDc3A01348Fe1A4a0D58494559A5c1f4836f1dE75")

// ABIItem represents a single item (function, event, etc.) in a contract ABI.
// We only need fields relevant for parsing events.
type ABIItem struct {
	Type            string      `json:"type"`
	Name            string      `json:"name"`
	Inputs          []ABIInput  `json:"inputs"`
	Anonymous       bool        `json:"anonymous"`       // Needed for abi.JSON parsing
	Outputs         []ABIOutput `json:"outputs"`         // Needed for abi.JSON parsing
	StateMutability string      `json:"stateMutability"` // Needed for abi.JSON parsing
}

// ABIInput represents an input parameter for an ABI item (event or function).
type ABIInput struct {
	Name    string `json:"name"`
	Type    string `json:"type"`
	Indexed bool   `json:"indexed"`
}

// ABIOutput represents an output parameter (needed for full ABI parsing compatibility).
type ABIOutput struct {
	Name string `json:"name"`
	Type string `json:"type"`
}

// GeneratedLog represents a structured Ethereum log with potential extra info.
// We embed types.Log for standard fields and add custom fields if needed.
type GeneratedLog struct {
	types.Log
	// Add any extra fields for context if desired, e.g.:
	// DecodedEventSignature string `json:"_decoded_event_signature,omitempty"`
}

func main() {
	// --- 1. Fetch ABI ---
	contractABI, err := FetchABI(ABIURL)
	if err != nil {
		log.Fatalf("Failed to fetch or parse ABI: %v", err)
	}

	// --- 2. Filter for Events ---
	events := FilterEvents(contractABI)
	if len(events) == 0 {
		log.Println("No events found in the provided ABI.")
		return
	}
	log.Printf("Found %d events in ABI.\n", len(events))

	// --- 3. Generate Logs ---
	allGeneratedLogs := make(map[string][]GeneratedLog)
	startBlockNumber := uint64(15000000) // Starting block number simulation
	var currentLogIndex uint             // Sequential log index across all generated logs

	for _, event := range events {
		log.Printf("Generating logs for event: %s\n", event.Name)
		generated, err := GenerateLogsForEvent(event, 10, startBlockNumber, currentLogIndex)
		if err != nil {
			log.Printf("WARN: Could not generate logs for event %s: %v\n", event.Name, err)
			continue
		}
		allGeneratedLogs[event.Name] = generated
		startBlockNumber += uint64(len(generated) / 5) // Increment block slightly
		currentLogIndex += uint(len(generated))        // Ensure unique log indices
	}

	// --- 4. Output Logs ---
	outputJSON, err := json.MarshalIndent(allGeneratedLogs, "", "  ")
	if err != nil {
		log.Fatalf("Failed to marshal generated logs to JSON: %v", err)
	}

	fmt.Println("\n--- Generated Ethereum Logs (JSON format) ---")
	fmt.Println(string(outputJSON))

	// Optionally write to a file
	// TODO: remove hardcoded path
	err = os.WriteFile("test-data/generated_logs.json", outputJSON, 0644)
	if err != nil {
		log.Printf("Failed to write logs to file: %v", err)
	}
}

// FetchABI retrieves the ABI from a given URL and parses it.
func FetchABI(url string) ([]ABIItem, error) {
	resp, err := http.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch ABI from %s: %w", url, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("failed to fetch ABI: received status code %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response body: %w", err)
	}

	var abiItems []ABIItem
	// Use the go-ethereum abi parser for robustness, it handles various ABI formats.
	// We need to marshal our simplified items back to JSON temporarily for this.
	// KunalL
	// tempJson, err := json.Marshal(abiItems)
	// if err != nil { // Should not happen with empty slice, but check
	// 	return nil, fmt.Errorf("internal error marshalling empty slice: %w", err)
	// }

	err = json.Unmarshal(body, &abiItems)
	if err != nil {
		// Fallback: try parsing with go-ethereum's ABI parser directly
		// This handles cases where the ABI structure is slightly different
		// but still valid for go-ethereum.
		parsedABI, errAbiParse := abi.JSON(bytes.NewReader(body))
		if errAbiParse != nil {
			return nil, fmt.Errorf("failed to parse ABI JSON (tried two methods): %w (abi parser error: %v)", err, errAbiParse)
		}
		// If successful, reconstruct our ABIItem slice from parsedABI.Events
		abiItems = []ABIItem{} // Reset
		for _, ev := range parsedABI.Events {
			item := ABIItem{
				Type:      "event",
				Name:      ev.Name,
				Anonymous: ev.Anonymous,
				Inputs:    []ABIInput{},
			}
			for _, input := range ev.Inputs {
				item.Inputs = append(item.Inputs, ABIInput{
					Name:    input.Name,
					Type:    input.Type.String(), // Get string representation of type
					Indexed: input.Indexed,
				})
			}
			abiItems = append(abiItems, item)
		}

	}

	return abiItems, nil
}

// FilterEvents extracts only the event definitions from a list of ABI items.
func FilterEvents(items []ABIItem) []ABIItem {
	var events []ABIItem
	for _, item := range items {
		if item.Type == "event" && !item.Anonymous { // Ignore anonymous events for standard logging
			events = append(events, item)
		}
	}
	return events
}

// GenerateLogsForEvent creates a specified number of sample logs for a given event definition.
func GenerateLogsForEvent(event ABIItem, count int, startBlock uint64, startLogIndex uint) ([]GeneratedLog, error) {
	if event.Type != "event" {
		return nil, fmt.Errorf("item provided is not an event (type: %s)", event.Type)
	}

	logs := make([]GeneratedLog, 0, count)

	// Build event signature string (e.g., "Transfer(address,address,uint256)")
	var inputTypes []string
	for _, input := range event.Inputs {
		inputTypes = append(inputTypes, input.Type)
	}
	signature := fmt.Sprintf("%s(%s)", event.Name, strings.Join(inputTypes, ","))

	// Calculate Keccak256 hash of the signature (Topic 0)
	hasher := sha3.NewLegacyKeccak256()
	hasher.Write([]byte(signature))
	topic0 := common.BytesToHash(hasher.Sum(nil))

	// Prepare ABI argument types for encoding non-indexed data
	var nonIndexedArgs abi.Arguments
	var indexedArgTypes []abi.Type // Keep track of indexed types for generation
	var indexedArgNames []string
	for _, input := range event.Inputs {
		abiType, err := abi.NewType(input.Type, "", nil)
		if err != nil {
			return nil, fmt.Errorf("invalid ABI type '%s' for input '%s': %w", input.Type, input.Name, err)
		}
		if input.Indexed {
			indexedArgTypes = append(indexedArgTypes, abiType)
			indexedArgNames = append(indexedArgNames, input.Name)
		} else {
			nonIndexedArgs = append(nonIndexedArgs, abi.Argument{Name: input.Name, Type: abiType})
		}
	}

	for i := 0; i < count; i++ {
		topics := []common.Hash{topic0}
		var nonIndexedValues []interface{} // Values for packing into data field

		// Generate and encode indexed parameters
		for idx, argType := range indexedArgTypes {
			value, err := generateRandomValue(argType.GetType()) // Use reflect Type from abi.Type
			if err != nil {
				return nil, fmt.Errorf("failed to generate random value for indexed param %s (%s): %w", indexedArgNames[idx], argType.String(), err)
			}

			// Encode indexed value to 32-byte topic
			var topic common.Hash
			switch v := value.(type) {
			case *big.Int:
				topic = common.BytesToHash(common.LeftPadBytes(v.Bytes(), 32))
			case common.Address:
				topic = common.BytesToHash(common.LeftPadBytes(v.Bytes(), 32))
			case bool:
				if v {
					topic[31] = 1 // Set the last byte to 1 for true
				}
				// Otherwise, it's already zeroed (false)
			case [32]byte:
				topic = common.BytesToHash(v[:])
			case string: // Often represents bytes or strings -> hash it for indexed topic
				// Note: Indexing strings or bytes stores their Keccak-256 hash
				hasher.Reset()
				hasher.Write([]byte(v))
				topic = common.BytesToHash(hasher.Sum(nil))
			case []byte: // Treat like string for indexing
				hasher.Reset()
				hasher.Write(v)
				topic = common.BytesToHash(hasher.Sum(nil))
			default:
				// Attempt general packing and use the bytes, though may not be standard for topics
				log.Printf("WARN: Attempting default packing for indexed topic type %T. This might not be standard.", value)
				packedBytes, err := abi.Arguments{{Type: argType}}.Pack(value)
				if err != nil {
					return nil, fmt.Errorf("failed to pack indexed value %s (%T) for topic: %w", indexedArgNames[idx], value, err)
				}
				topic = common.BytesToHash(common.LeftPadBytes(packedBytes, 32))
			}
			topics = append(topics, topic)
		}

		// Generate non-indexed parameters
		for _, arg := range nonIndexedArgs {
			value, err := generateRandomValue(arg.Type.GetType()) // Use reflect Type
			if err != nil {
				return nil, fmt.Errorf("failed to generate random value for non-indexed param %s (%s): %w", arg.Name, arg.Type.String(), err)
			}
			nonIndexedValues = append(nonIndexedValues, value)
		}

		// Pack non-indexed parameters into the data field
		data, err := nonIndexedArgs.Pack(nonIndexedValues...)
		if err != nil {
			return nil, fmt.Errorf("failed to pack non-indexed data for event %s: %w", event.Name, err)
		}

		// Generate random metadata
		blockNum := startBlock + uint64(i/5) // Simulate ~5 logs per block
		txIndex := uint(i % 5)
		logIndex := startLogIndex + uint(i)
		txHash := generateRandomHash()
		blockHash := generateRandomHash() // Ideally related to blockNum, random ok for testing

		// Create the log entry
		logEntry := GeneratedLog{
			Log: types.Log{
				Address:     PlaceholderContractAddress,
				Topics:      topics,
				Data:        data,
				BlockNumber: blockNum,
				TxHash:      txHash,
				TxIndex:     txIndex,
				BlockHash:   blockHash,
				Index:       logIndex,
				Removed:     false, // Logs are typically not removed
			},
			// DecodedEventSignature: signature, // Optional: include for easier debugging
		}
		logs = append(logs, logEntry)
	}

	return logs, nil
}

// generateRandomValue creates a plausible random value based on an ABI type.
// It uses the reflect.Type obtained from abi.Type.GetType().
func generateRandomValue(t reflect.Type) (interface{}, error) {
	switch t.Kind() {
	case reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
		// Generate *big.Int for uint types for consistency with uint256
		maxVal := new(big.Int)
		maxVal.SetString("1000000000000000000", 10) // Arbitrary reasonable max for samples
		randBig, err := rand.Int(rand.Reader, maxVal)
		if err != nil {
			return nil, fmt.Errorf("failed to generate random big.Int: %w", err)
		}
		return randBig, nil
	case reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
		// Generate *big.Int for int types as well
		maxVal := big.NewInt(1000000000) // Arbitrary range
		minVal := big.NewInt(-1000000000)
		rangeVal := new(big.Int).Sub(maxVal, minVal)
		randBig, err := rand.Int(rand.Reader, rangeVal)
		if err != nil {
			return nil, fmt.Errorf("failed to generate random big.Int: %w", err)
		}
		randBig.Add(randBig, minVal) // Shift to correct range
		return randBig, nil
	case reflect.Ptr: // Handles *big.Int case
		if t.Elem().Kind() == reflect.Struct && t.Elem().Name() == "Int" && t.Elem().PkgPath() == "math/big" {
			maxVal := new(big.Int)
			// Example: up to 2^128 for uint256 samples
			maxVal.Lsh(big.NewInt(1), 128)
			randBig, err := rand.Int(rand.Reader, maxVal)
			if err != nil {
				return nil, fmt.Errorf("failed to generate random big.Int (ptr): %w", err)
			}
			return randBig, nil
		}
	case reflect.Bool:
		b := make([]byte, 1)
		_, err := rand.Read(b)
		if err != nil {
			return nil, fmt.Errorf("failed to generate random bool byte: %w", err)
		}
		return b[0]%2 == 0, nil // Simple way to get true/false
	case reflect.Array:
		// Handle address ([20]byte) and bytes32 ([32]byte)
		if t.Len() == 20 && t.Elem().Kind() == reflect.Uint8 { // Address
			var addr common.Address
			_, err := rand.Read(addr[:])
			if err != nil {
				return nil, fmt.Errorf("failed to generate random address bytes: %w", err)
			}
			return addr, nil
		} else if t.Len() == 32 && t.Elem().Kind() == reflect.Uint8 { // Bytes32
			var b32 [32]byte
			_, err := rand.Read(b32[:])
			if err != nil {
				return nil, fmt.Errorf("failed to generate random bytes32: %w", err)
			}
			return b32, nil
		}
	case reflect.Slice:
		if t.Elem().Kind() == reflect.Uint8 { // bytes
			size := 10 + int(generateRandomUint(10)) // Random size 10-19 bytes
			b := make([]byte, size)
			_, err := rand.Read(b)
			if err != nil {
				return nil, fmt.Errorf("failed to generate random bytes slice: %w", err)
			}
			return b, nil
		}
	case reflect.String: // string
		size := 10 + int(generateRandomUint(20)) // Random size 10-29 chars
		b := make([]byte, size)
		if _, err := rand.Read(b); err != nil {
			return nil, fmt.Errorf("failed to generate random string bytes: %w", err)
		}
		// Ensure printable characters for easier debugging, replace non-printable
		for i := range b {
			if b[i] < 32 || b[i] > 126 {
				b[i] = byte(65 + (b[i] % 26)) // Replace with A-Z
			}
		}
		return string(b), nil

		// Add cases for other types like arrays, structs if needed
	}

	return nil, fmt.Errorf("unsupported ABI type for random value generation: %v (Kind: %s)", t, t.Kind())
}

// generateRandomHash creates a random 32-byte hash.
func generateRandomHash() common.Hash {
	var h common.Hash
	_, err := rand.Read(h[:])
	if err != nil {
		// This should realistically never fail with crypto/rand
		log.Panicf("Failed to read random bytes for hash: %v", err)
	}
	return h
}

// generateRandomUint generates a random uint64 up to a max value.
func generateRandomUint(max uint64) uint64 {
	nBig, err := rand.Int(rand.Reader, big.NewInt(int64(max)))
	if err != nil {
		log.Printf("WARN: Failed to generate random uint, using fallback: %v", err)
		// Fallback to pseudo-random if crypto/rand fails (unlikely)
		return uint64(time.Now().UnixNano()) % max
	}
	return nBig.Uint64()
}
