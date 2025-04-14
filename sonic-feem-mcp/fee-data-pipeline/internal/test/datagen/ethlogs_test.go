package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"math/big"
	"net/http"
	"net/http/httptest"
	"os"
	"reflect"
	"strings"
	"testing"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"golang.org/x/crypto/sha3"
)

// --- Test Helpers ---

// Mock ABI server
func setupMockABIServer(t *testing.T, abiContent string) *httptest.Server {
	t.Helper()
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/mock-abi.json" {
			http.NotFound(w, r)
			return
		}
		w.WriteHeader(http.StatusOK)
		fmt.Fprintln(w, abiContent)
	}))
	return server
}

// Sample valid ABI content for testing
const sampleABIContent = `[
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "user",
          "type": "address"
        },
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        },
		{
		  "indexed": true,
		  "internalType": "bytes32",
		  "name": "dataHash",
		  "type": "bytes32"
		}
      ],
      "name": "DataProcessed",
      "type": "event"
    },
	{
      "anonymous": false,
      "inputs": [
        {
          "indexed": false,
          "internalType": "bool",
          "name": "success",
          "type": "bool"
        }
      ],
      "name": "SimpleEvent",
      "type": "event"
    },
    {
      "inputs": [],
      "name": "doSomething",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }
  ]`

// --- Test Cases ---

// TestFetchABI tests fetching and parsing the ABI.
func TestFetchABI(t *testing.T) {
	server := setupMockABIServer(t, sampleABIContent)
	defer server.Close()

	abiItems, err := FetchABI(server.URL + "/mock-abi.json")
	if err != nil {
		t.Fatalf("FetchABI failed: %v", err)
	}

	if len(abiItems) != 3 { // 2 events + 1 function
		t.Errorf("Expected 3 ABI items, got %d", len(abiItems))
	}

	// Check if event types are correctly identified (more detailed checks in FilterEvents test)
	eventCount := 0
	funcCount := 0
	for _, item := range abiItems {
		if item.Type == "event" {
			eventCount++
		} else if item.Type == "function" {
			funcCount++
		}
	}
	if eventCount != 2 {
		t.Errorf("Expected 2 events parsed, got %d", eventCount)
	}
	if funcCount != 1 {
		t.Errorf("Expected 1 function parsed, got %d", funcCount)
	}

}

// TestFetchABIFailure tests error handling during fetch/parse.
func TestFetchABIFailure(t *testing.T) {
	// Test invalid URL
	_, err := FetchABI("invalid-url")
	if err == nil {
		t.Error("Expected error for invalid URL, got nil")
	}

	// Test server error
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		http.Error(w, "server error", http.StatusInternalServerError)
	}))
	defer server.Close()
	_, err = FetchABI(server.URL)
	if err == nil {
		t.Error("Expected error for server error status, got nil")
	}

	// Test invalid JSON
	server = setupMockABIServer(t, `[{"type": "event", "name": "MissingQuotes}`)
	defer server.Close()
	_, err = FetchABI(server.URL + "/mock-abi.json")
	if err == nil {
		t.Error("Expected error for invalid JSON, got nil")
	} else if !strings.Contains(err.Error(), "failed to parse ABI JSON") {
		t.Errorf("Expected JSON parsing error, got: %v", err)
	}
}

// TestFilterEvents tests the filtering logic.
func TestFilterEvents(t *testing.T) {
	// Manually create ABI items for precise testing
	items := []ABIItem{
		{Type: "function", Name: "func1"},
		{Type: "event", Name: "Event1", Anonymous: false, Inputs: []ABIInput{{Name: "p1", Type: "uint256", Indexed: false}}},
		{Type: "constructor"},
		{Type: "event", Name: "Event2", Anonymous: true}, // Should be filtered out
		{Type: "event", Name: "Event3", Anonymous: false, Inputs: []ABIInput{{Name: "addr", Type: "address", Indexed: true}}},
	}

	events := FilterEvents(items)

	if len(events) != 2 {
		t.Fatalf("Expected 2 non-anonymous events, got %d", len(events))
	}
	if events[0].Name != "Event1" {
		t.Errorf("Expected first event to be 'Event1', got '%s'", events[0].Name)
	}
	if events[1].Name != "Event3" {
		t.Errorf("Expected second event to be 'Event3', got '%s'", events[1].Name)
	}
}

// TestGenerateLogsForEvent tests the core log generation logic.
func TestGenerateLogsForEvent(t *testing.T) {
	// Parse the sample ABI to get a valid event definition
	tempFile, err := os.CreateTemp("", "testabi*.json")
	if err != nil {
		t.Fatalf("Failed to create temp file: %v", err)
	}
	defer os.Remove(tempFile.Name())
	_, err = tempFile.WriteString(sampleABIContent)
	if err != nil {
		t.Fatalf("Failed to write to temp file: %v", err)
	}
	tempFile.Close() // Close before reading

	fileBytes, err := os.ReadFile(tempFile.Name())
	if err != nil {
		t.Fatalf("Failed to read back temp file: %v", err)
	}

	var testABIItems []ABIItem
	err = json.Unmarshal(fileBytes, &testABIItems)
	if err != nil {
		t.Fatalf("Failed to unmarshal sample ABI for test: %v", err)
	}

	var dataProcessedEvent ABIItem
	found := false
	for _, item := range testABIItems {
		if item.Type == "event" && item.Name == "DataProcessed" {
			dataProcessedEvent = item
			found = true
			break
		}
	}
	if !found {
		t.Fatal("Could not find 'DataProcessed' event in sample ABI for testing")
	}

	// Generate logs
	logCount := 5
	startBlock := uint64(1000)
	startLogIndex := uint(10)
	logs, err := GenerateLogsForEvent(dataProcessedEvent, logCount, startBlock, startLogIndex)
	if err != nil {
		t.Fatalf("GenerateLogsForEvent failed: %v", err)
	}

	if len(logs) != logCount {
		t.Fatalf("Expected %d logs, got %d", logCount, len(logs))
	}

	// --- Check structure and content of the first log ---
	l := logs[0]

	// 1. Check Metadata
	if l.Address != PlaceholderContractAddress {
		t.Errorf("Expected address %s, got %s", PlaceholderContractAddress.Hex(), l.Address.Hex())
	}
	if l.BlockNumber != startBlock { // First log should be at startBlock
		t.Errorf("Expected block number %d, got %d", startBlock, l.BlockNumber)
	}
	if l.Index != startLogIndex {
		t.Errorf("Expected log index %d, got %d", startLogIndex, l.Index)
	}
	if len(l.TxHash.Bytes()) != 32 || l.TxHash == (common.Hash{}) {
		t.Error("TxHash looks invalid (zero or wrong length)")
	}
	if len(l.BlockHash.Bytes()) != 32 || l.BlockHash == (common.Hash{}) {
		t.Error("BlockHash looks invalid (zero or wrong length)")
	}

	// 2. Check Topics
	// Expected signature: DataProcessed(address,uint256,bytes32)
	expectedSig := "DataProcessed(address,uint256,bytes32)"
	hasher := sha3.NewLegacyKeccak256()
	hasher.Write([]byte(expectedSig))
	expectedTopic0 := common.BytesToHash(hasher.Sum(nil))

	if len(l.Topics) != 3 { // Topic0 + 2 indexed params (address, bytes32)
		t.Fatalf("Expected 3 topics, got %d", len(l.Topics))
	}
	if l.Topics[0] != expectedTopic0 {
		t.Errorf("Topic0 mismatch. Expected %s, got %s", expectedTopic0.Hex(), l.Topics[0].Hex())
	}
	// Topics[1] (indexed address) and Topics[2] (indexed bytes32) should be 32 bytes long
	if len(l.Topics[1].Bytes()) != 32 || l.Topics[1] == (common.Hash{}) {
		t.Errorf("Topic1 (indexed address) seems invalid: %s", l.Topics[1].Hex())
	}
	if len(l.Topics[2].Bytes()) != 32 || l.Topics[2] == (common.Hash{}) {
		t.Errorf("Topic2 (indexed bytes32) seems invalid: %s", l.Topics[2].Hex())
	}

	// 3. Check Data field (non-indexed uint256 amount)
	if len(l.Data) == 0 || !bytes.HasPrefix(l.Data, []byte{0x0}) { // Should not be empty
		t.Errorf("Data field is empty or seems invalid for uint256: %x", l.Data)
	}
	// Try to unpack the data to verify type - requires go-ethereum ABI parsing
	eventAbi, err := abi.JSON(strings.NewReader(sampleABIContent)) // Parse full ABI with go-ethereum
	if err != nil {
		t.Fatalf("Failed to parse sample ABI with go-ethereum: %v", err)
	}
	// KunalL
	_ = eventAbi
	// var decodedAmount *big.Int
	// err = eventAbi.UnpackIntoInterface(&decodedAmount, "DataProcessed", l.Data) // Unpack only non-indexed
	// if err != nil {
	// 	t.Errorf("Failed to unpack non-indexed data from log: %v\nData: %x", err, l.Data)
	// }
	// if decodedAmount == nil || decodedAmount.Sign() < 0 { // Should be a non-negative uint256
	// 	t.Errorf("Decoded non-indexed amount seems invalid: %v", decodedAmount)
	// }

	// 4. Check subsequent log indices and block numbers
	if logs[1].Index != startLogIndex+1 {
		t.Errorf("Expected log index %d for second log, got %d", startLogIndex+1, logs[1].Index)
	}
	// Block number might increment based on i/5 logic
	expectedBlockLog1 := startBlock + uint64(1/5) // Stays the same
	if logs[1].BlockNumber != expectedBlockLog1 {
		t.Errorf("Expected block number %d for second log, got %d", expectedBlockLog1, logs[1].BlockNumber)
	}
	expectedBlockLog4 := startBlock + uint64(4/5) // Stays the same
	if logs[4].BlockNumber != expectedBlockLog4 {
		t.Errorf("Expected block number %d for 5th log, got %d", expectedBlockLog4, logs[4].BlockNumber)
	}
}

// TestGenerateRandomValue covers different types for random generation.
func TestGenerateRandomValue(t *testing.T) {
	testCases := []struct {
		name     string
		typeName string // ABI type string
		kind     reflect.Kind
		elemKind reflect.Kind // For pointers/slices/arrays
		length   int          // For arrays
	}{
		{"Uint256", "uint256", reflect.Ptr, reflect.Struct, 0}, // Handled as *big.Int
		{"Address", "address", reflect.Array, reflect.Uint8, 20},
		{"Bytes32", "bytes32", reflect.Array, reflect.Uint8, 32},
		{"Bool", "bool", reflect.Bool, 0, 0},
		{"Uint64", "uint64", reflect.Uint64, 0, 0}, // Handled as *big.Int
		{"Bytes", "bytes", reflect.Slice, reflect.Uint8, 0},
		{"String", "string", reflect.String, 0, 0},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			abiType, err := abi.NewType(tc.typeName, "", nil)
			if err != nil {
				t.Fatalf("Failed to create abi.Type for '%s': %v", tc.typeName, err)
			}
			value, err := generateRandomValue(abiType.GetType()) // Use reflect.Type
			if err != nil {
				t.Fatalf("generateRandomValue failed for type %s: %v", tc.typeName, err)
			}

			// Basic type kind check
			valType := reflect.TypeOf(value)
			if valType.Kind() != tc.kind {
				// Special case for uint/int which we return as *big.Int
				if strings.HasPrefix(tc.typeName, "uint") || strings.HasPrefix(tc.typeName, "int") {
					if valType.Kind() != reflect.Ptr || valType.Elem().Name() != "Int" {
						t.Errorf("Expected *big.Int for type %s, got %T", tc.typeName, value)
					}
				} else {
					t.Errorf("Expected kind %v for type %s, got %v (%T)", tc.kind, tc.typeName, valType.Kind(), value)
				}
			}

			// Check element kind and length for arrays/slices if applicable
			if tc.kind == reflect.Array {
				if valType.Elem().Kind() != tc.elemKind {
					t.Errorf("Expected array element kind %v, got %v", tc.elemKind, valType.Elem().Kind())
				}
				if valType.Len() != tc.length {
					t.Errorf("Expected array length %d, got %d", tc.length, valType.Len())
				}
				// Ensure non-zero value for array types
				isZero := true
				arrValue := reflect.ValueOf(value)
				for i := 0; i < arrValue.Len(); i++ {
					if arrValue.Index(i).Interface().(byte) != 0 {
						isZero = false
						break
					}
				}
				if isZero {
					t.Error("Generated array value is zero")
				}

			} else if tc.kind == reflect.Slice && tc.elemKind != 0 {
				if valType.Elem().Kind() != tc.elemKind {
					t.Errorf("Expected slice element kind %v, got %v", tc.elemKind, valType.Elem().Kind())
				}
				// Check slice has non-zero length
				if reflect.ValueOf(value).Len() == 0 {
					t.Error("Generated slice has zero length")
				}
			}

			// Check non-zero for uint256 (*big.Int)
			if tc.name == "Uint256" {
				if value.(*big.Int).Sign() == 0 {
					// It's possible but highly unlikely to generate exactly 0 with crypto/rand
					t.Logf("WARN: Generated uint256 is zero, which is possible but rare.")
				}
			}
		})
	}
}
