package config

import (
	"flag"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Helper function to set environment variables for a test
func setEnvVars(t *testing.T, vars map[string]string) {
	t.Helper()
	for key, value := range vars {
		// Setenv automatically calls t.Cleanup to restore the variable
		t.Setenv(key, value)
	}
}

// Helper function to clear specific environment variables for a test
func clearEnvVars(t *testing.T, keys []string) {
	t.Helper()
	originalValues := make(map[string]string)
	for _, key := range keys {
		originalValues[key] = os.Getenv(key) // Store original value
		os.Unsetenv(key)                     // Unset the variable
	}

	// Use t.Cleanup to restore the original values after the test
	t.Cleanup(func() {
		for _, key := range keys {
			if val, ok := originalValues[key]; ok {
				os.Setenv(key, val)
			} else {
				os.Unsetenv(key) // Ensure it remains unset if it wasn't set originally
			}
		}
	})
}

func TestParseAndValidate(t *testing.T) {

	// --- Test Cases ---
	tests := []struct {
		name        string
		setupEnv    map[string]string // Variables to set
		clearEnv    []string          // Variables to explicitly unset (if needed)
		expectError bool
		expectedCfg *Config
	}{
		{
			name: "Success - All values provided via env",
			setupEnv: map[string]string{
				"ENDPOINT":         "http://localhost:8545",
				"CONTRACT_ADDRESS": "0x1234567890abcdef",
				"CHAIN_TYPE":       "OPTIMISM",
			},
			expectError: false,
			expectedCfg: &Config{
				Endpoint:        "http://localhost:8545",
				ContractAddress: "0x1234567890abcdef",
				ChainType:       "OPTIMISM",
			},
		},
		{
			name: "Success - Optional values missing, default used",
			setupEnv: map[string]string{
				"ENDPOINT": "http://required-endpoint:8080",
				// CONTRACT_ADDRESS is optional
				// CHAIN_TYPE will use default
			},
			clearEnv:    []string{"CONTRACT_ADDRESS", "CHAIN_TYPE"}, // Ensure they are not set from previous runs or system env
			expectError: false,
			expectedCfg: &Config{
				Endpoint:        "http://required-endpoint:8080",
				ContractAddress: "",    // Optional, should be empty string
				ChainType:       "EVM", // Default value
			},
		},
		{
			name: "Failure - Required value missing",
			setupEnv: map[string]string{
				// ENDPOINT is required but missing
				"CONTRACT_ADDRESS": "0xabcdef1234567890",
				"CHAIN_TYPE":       "POLYGON",
			},
			clearEnv:    []string{"ENDPOINT"}, // Ensure ENDPOINT is not set
			expectError: true,                 // Expecting an error because ENDPOINT is required
			expectedCfg: &Config{ // The state of config might be partially populated or zero depending on env.ProcessConfig
				ContractAddress: "0xabcdef1234567890",
				ChainType:       "POLYGON",
			},
		},
		{
			name: "Success - Only required value provided",
			setupEnv: map[string]string{
				"ENDPOINT": "ws://another-endpoint:9000",
			},
			clearEnv:    []string{"CONTRACT_ADDRESS", "CHAIN_TYPE"}, // Ensure optional/default are not set
			expectError: false,
			expectedCfg: &Config{
				Endpoint:        "ws://another-endpoint:9000",
				ContractAddress: "",
				ChainType:       "EVM", // Default
			},
		},
	}

	// --- Run Tests ---
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			flag.CommandLine = flag.NewFlagSet(os.Args[0], flag.ExitOnError) // reset
			// --- Setup ---
			// Clear potentially interfering env vars first
			if len(tc.clearEnv) > 0 {
				clearEnvVars(t, tc.clearEnv)
			}
			// Set specific env vars for this test case
			if len(tc.setupEnv) > 0 {
				setEnvVars(t, tc.setupEnv)
			}

			// --- Execute ---
			cfg, err := ParseAndValidate()

			// --- Verify ---
			if tc.expectError {
				assert.Error(t, err, "Expected an error but got none")
				// Note: We don't assert the exact error message as it depends
				// on the underlying 'env.ProcessConfig' implementation.
				// We also check the config state *if* an error was expected,
				// as it might be partially populated.
				if tc.expectedCfg != nil && cfg != nil {
					// Check fields that might have been set before the error occurred
					if tc.expectedCfg.ContractAddress != "" {
						assert.Equal(t, tc.expectedCfg.ContractAddress, cfg.ContractAddress)
					}
					if tc.expectedCfg.ChainType != "" {
						assert.Equal(t, tc.expectedCfg.ChainType, cfg.ChainType)
					}
					// The required field that caused the error might be zero/empty
					if tc.expectedCfg.Endpoint == "" {
						assert.Empty(t, cfg.Endpoint)
					}
				}
			} else {
				require.NoError(t, err, "Expected no error but got: %v", err)
				require.NotNil(t, cfg, "Config should not be nil on success")
				assert.Equal(t, tc.expectedCfg, cfg, "Config values do not match expected")
			}
		})
	}
}
