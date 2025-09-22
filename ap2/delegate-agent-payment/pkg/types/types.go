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
	// Nonce is a large random number to ensure the uniqueness of the intent hash.
	Nonce *big.Int `json:"nonce"`
}
// DeployedContracts holds the addresses of the deployed contracts.
type DeployedContracts struct {
	TokenUSDC          common.Address `json:"token_usdc"`
	PaymentFacilitator common.Address `json:"payment_facilitator"`
}

// TaskData holds the user's signed mandate and the signature itself.
// This struct is serialized to JSON and read by the agent script.
type TaskData struct {
	// Mandate is the user's intent.
	Mandate *IntentMandate `json:"mandate"`
	// Signature is the 65-byte EIP-712 signature of the mandate.
	Signature []byte `json:"signature"`
}

// Cart represents the merchant's bill, which will be signed.
// This struct must match the CartMandate in the Solidity contract.
type Cart struct {
	Merchant common.Address `json:"merchant"`
	Token    common.Address `json:"token"`
	Amount   *big.Int       `json:"amount"`
}

// SignedCart is the structure returned by the merchant's /cart endpoint.
type SignedCart struct {
	Cart      *Cart  `json:"cart"`
	Signature []byte `json:"signature"`
}