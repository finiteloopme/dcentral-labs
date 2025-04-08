package chain

import (
	"context"
	"fmt"
	"os" // Use os package for file operations
	"strings"

	"github.com/apache/beam/sdks/v2/go/pkg/beam/log"
	"github.com/ethereum/go-ethereum/accounts/abi"
	// "github.com/ethereum/go-ethereum/common" // No longer needed here
)

// LoadABIFromFile reads a contract ABI JSON from a local file path.
// It returns the parsed ABI object, the raw ABI string content, and an error.
func LoadABIFromFile(ctx context.Context, filePath string) (*abi.ABI, string, error) {
	if filePath == "" {
		return nil, "", fmt.Errorf("ABI file path is empty")
	}

	log.Infof(ctx, "Loading ABI from file: %s", filePath)

	// Read the entire file content
	abiBytes, err := os.ReadFile(filePath)
	if err != nil {
		return nil, "", fmt.Errorf("failed to read ABI file '%s': %w", filePath, err)
	}

	abiString := string(abiBytes)
	if abiString == "" {
		return nil, "", fmt.Errorf("ABI file '%s' is empty", filePath)
	}

	// Parse the ABI JSON string
	parsedABI, err := abi.JSON(strings.NewReader(abiString))
	if err != nil {
		// Provide more context in the error message
		return nil, "", fmt.Errorf("failed to parse ABI JSON from file '%s': %w", filePath, err)
	}

	log.Infof(ctx, "Successfully parsed ABI from file '%s'", filePath)
	return &parsedABI, abiString, nil
}
