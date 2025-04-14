package transforms

import (
	"os"
	"strings"
	"testing"

	"github.com/apache/beam/sdks/v2/go/pkg/beam"
	"github.com/apache/beam/sdks/v2/go/pkg/beam/testing/ptest"

	//"github.com/apache/beam/sdks/v2/go/pkg/beam/testing/testdata"

	"github.com/ethereum/go-ethereum/accounts/abi"
)

func loadFiles(t *testing.T) (string, *abi.ABI) {
	// Load sample data from test-data/generated_logs.json
	rawJson, err := os.ReadFile("/Users/kunall/scratchpad/dcentral-labs/sonic-feem-mcp/fee-data-pipeline/test-data/generated_logs.json") // returns []byte
	if err != nil {
		t.Fatal(err)
	}

	sampleData := string(rawJson)
	// var sampleData string
	// if err := json.Unmarshal(rawJson, &sampleData); err != nil {
	// 	// Check JSON encoding
	// 	t.Fatal(err)
	// }
	// Load ABI from file
	abiJSON, err := os.ReadFile("/Users/kunall/scratchpad/dcentral-labs/sonic-feem-mcp/fee-data-pipeline/feem-abi.json")
	if err != nil {
		t.Fatal(err)
	}
	// Parse the ABI
	parsedABI, err := abi.JSON(strings.NewReader(string(abiJSON)))
	if err != nil {
		t.Fatal(err)
	}

	return sampleData, &parsedABI
}
func TestEncodeToABIFn(t *testing.T) {
	// TODO: fix this to filter through file Contents
	ptest.BuildAndRun(t, func(s beam.Scope) {

		// sampleData, parsedABI := loadFiles(t)
		// // Create a PCollection from the sample data
		// logs := beam.Create(s, sampleData)

		// // Apply the encodeToABIFn transform
		// beam.ParDo(
		// 	s,
		// 	NewEncodeToABIFn(parsedABI),
		// 	logs,
		// )

		// // Count the number of encoded logs
		// // count := encodedLogs | stats.Count()

		// // Assert that the count is correct
		// // if count != len(sampleData) {
		// // 	t.Errorf("Expected %d encoded logs, got %d", len(sampleData), count)
		// // }
	})

	// Execute the pipeline
	// if err := ptest.BuildAndRun(t, s); err != nil {
	// 	t.Fatal(err)
	// }
}

func TestEncodeToABIFnDecodeEvent(t *testing.T) {
	ptest.BuildAndRun(t, func(s beam.Scope) {
		// sampleData, parsedABI := loadFiles(t)
		// // Apply the encodeToABIFn transform
		// encodedLogs := logs | beam.ParDo(NewEncodeToABIFn(parsedABI), beam.TypeDefinition{Var: beam.TypeName("types.Log")})

		// // Decode the first log
		// firstLog := encodedLogs | beam.Take(1)

		// // Assert that the first log is correctly decoded
		// firstLogJSON, err := json.Marshal(firstLog)
		// if err != nil {
		// 	t.Fatal(err)
		// }
		// var firstLogEvent abi.Event
		// err = json.Unmarshal(firstLogJSON, &firstLogEvent)
		// if err != nil {
		// 	t.Fatal(err)
		// }
		// if firstLogEvent.Name != "DataProcessed" {
		// 	t.Errorf("Expected event name 'DataProcessed', got '%s'", firstLogEvent.Name)
		// }

		// // Execute the pipeline
		// if err := ptest.RunPipeline(p); err != nil {
		// 	t.Fatal(err)
		// }
	})

}
