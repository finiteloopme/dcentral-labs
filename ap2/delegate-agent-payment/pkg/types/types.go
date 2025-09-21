// Package types defines shared data structures used across the application.
package types

import (
	"math/big"

	"github.com/ethereum/go-ethereum/common"
)

// IntentMandate represents the user's off-chain instructions.
// This struct's layout and types must be compatible with the EIP-712 signing
// process and the corresponding struct in the AgentProxy smart contract.
type IntentMandate struct {
	// Task is a human-readable description of the intent.
	Task string `json:"task"`
	// Token is the address of the ERC20 token to be used for payment.
	Token common.Address `json:"token"`
	// MaxPrice is the maximum amount of the token that can be spent.
	MaxPrice *big.Int `json:"maxPrice"`
	// Expires is the Unix timestamp when this intent becomes invalid.
	Expires *big.Int `json:"expires"`
	// ProxyContract is the address of the user's AgentProxy contract.
	ProxyContract common.Address `json:"proxyContract"`
	// Nonce is a large random number to ensure the uniqueness of the intent hash.
	Nonce *big.Int `json:"nonce"`
}

// DeployedContracts holds the addresses of the contracts deployed by the user setup script.
// This struct is serialized to JSON and read by the agent script.
type DeployedContracts struct {
	// TokenUSDC is the address of the deployed ERC20 token contract.
	TokenUSDC common.Address `json:"token_usdc"`
	// AgentProxy is the address of the deployed AgentProxy contract.
	AgentProxy common.Address `json:"agent_proxy"`
}

// TaskData holds the user's signed mandate and the signature itself.
// This struct is serialized to JSON and read by the agent script.
type TaskData struct {
	// Mandate is the user's intent.
	Mandate *IntentMandate `json:"mandate"`
	// Signature is the 65-byte EIP-712 signature of the mandate.
	Signature []byte `json:"signature"`
}