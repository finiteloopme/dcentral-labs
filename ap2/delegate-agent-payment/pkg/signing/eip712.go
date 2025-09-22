// Package signing provides functions for creating EIP-712 compliant signatures.
// EIP-712 is a standard for hashing and signing typed structured data instead of just byte strings.
// This allows wallets to display the data in a human-readable format, improving security.
package signing

import (
	"crypto/ecdsa"
	"fmt"
	"log"
	"math/big"

	"delegated-agent-demo/pkg/types"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/common/math"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/signer/core/apitypes"
)

// EIP712DomainName is the `name` in the EIP712 Domain constructor.
// This MUST match the name in the `PaymentFacilitator.sol` constructor for signatures to be valid.
const EIP712DomainName = "PaymentFacilitator"

// EIP712DomainVersion is the `version` in the EIP712 Domain constructor.
// This MUST match the version in the `PaymentFacilitator.sol` constructor.
const EIP712DomainVersion = "1"

// SignIntentMandate signs an IntentMandate struct according to the EIP-712 standard.
// It constructs the typed data, hashes it, signs the hash, and returns the signature.
// The output signature is a 65-byte array in [R || S || V] format.
//
// Parameters:
//   - mandate: The IntentMandate struct to be signed.
//   - verifyingContract: The address of the smart contract that will verify the signature.
//   - privateKey: The private key of the user to sign the mandate with.
//   - chainID: The ID of the blockchain where the contract is deployed.
//
// Returns:
//   - A 65-byte signature in [R || S || V] format.
//   - An error if the signing process fails.
func SignIntentMandate(
	mandate *types.IntentMandate,
	verifyingContract common.Address,
	privateKey *ecdsa.PrivateKey,
	chainID *big.Int,
) ([]byte, error) {

	log.Println("Signing EIP-712 IntentMandate...")

	// 1. Define the EIP-712 TypedData structure.
	// This structure must EXACTLY MATCH the layout and types defined in the
	// PaymentFacilitator.sol smart contract, including the EIP712Domain and the IntentMandate struct.
	typedData := apitypes.TypedData{
		Types: apitypes.Types{
			"EIP712Domain": []apitypes.Type{
				{Name: "name", Type: "string"},
				{Name: "version", Type: "string"},
				{Name: "chainId", Type: "uint256"},
				{Name: "verifyingContract", Type: "address"},
			},
			// This is the primary type for the message, matching the struct name in Solidity.
			"IntentMandate": []apitypes.Type{
				{Name: "task", Type: "bytes32"}, // Must match the contract's type
				{Name: "token", Type: "address"},
				{Name: "maxPrice", Type: "uint256"},
				{Name: "expires", Type: "uint256"},
				{Name: "nonce", Type: "uint256"},
			},
		},
		// Domain is the EIP-712 domain separator data. It ensures that a signature
		// is unique to a specific domain (e.g., a specific contract on a specific chain).
		Domain: apitypes.TypedDataDomain{
			Name:              EIP712DomainName,
				Version:           EIP712DomainVersion,
				ChainId:           (*math.HexOrDecimal256)(chainID),
				VerifyingContract: verifyingContract.Hex(),
		},
		// Message is the actual data to be signed.
		Message: apitypes.TypedDataMessage{
			// The `task` field is a string in the Go struct, but the contract expects a bytes32 hash.
			// We hash it here to match the contract's expectation.
			"task":          crypto.Keccak256Hash([]byte(mandate.Task)),
			"token":         mandate.Token.Hex(),
			"maxPrice":      (*math.HexOrDecimal256)(mandate.MaxPrice),
			"expires":       (*math.HexOrDecimal256)(mandate.Expires),
			"nonce":         (*math.HexOrDecimal256)(mandate.Nonce),
		},
		PrimaryType: "IntentMandate",
	}

	// 2. Hash the typed data struct to get the digest to be signed.
	// The EIP-712 standard specifies a hashing algorithm that involves hashing the domain separator
	// and the struct hash, and then hashing the result.
	domainSeparator, err := typedData.HashStruct("EIP712Domain", typedData.Domain.Map())
	if err != nil {
		return nil, fmt.Errorf("failed to hash domain separator: %w", err)
	}
	typedDataHash, err := typedData.HashStruct(typedData.PrimaryType, typedData.Message)
	if err != nil {
		return nil, fmt.Errorf("failed to hash typed data: %w", err)
	}

	// The final hash to sign is keccak256("\x19\x01" + domainSeparator + typedDataHash).
	hashToSign := []byte{0x19, 0x01}
	hashToSign = append(hashToSign, domainSeparator...)
	hashToSign = append(hashToSign, typedDataHash...)
	finalHash := crypto.Keccak256(hashToSign)

	// 3. Sign the final hash with the provided private key.
	signature, err := crypto.Sign(finalHash, privateKey)
	if err != nil {
		return nil, err
	}

	// 4. Adjust the 'V' value of the signature.
	// The `crypto.Sign` function returns V as 0 or 1, but Ethereum RPCs expect it
	// to be 27 or 28. We add 27 to the value to make it compliant.
	signature[64] += 27

	log.Printf("...Signature successful: 0x%x\n", signature)
	return signature, nil
}

// SignCartMandate signs a Cart struct according to the EIP-712 standard.
// It follows the same process as SignIntentMandate but for the Cart struct.
//
// Parameters:
//   - cart: The Cart struct to be signed.
//   - verifyingContract: The address of the smart contract that will verify the signature.
//   - privateKey: The private key of the merchant to sign the cart with.
//   - chainID: The ID of the blockchain where the contract is deployed.
//
// Returns:
//   - A 65-byte signature in [R || S || V] format.
//   - An error if the signing process fails.
func SignCartMandate(

cart *types.Cart,
	verifyingContract common.Address,
	privateKey *ecdsa.PrivateKey,
	chainID *big.Int,
) ([]byte, error) {

	log.Println("Signing EIP-712 Cart...")

	// 1. Get the EIP-712 TypedData structure for the cart.
	typedData, err := GetCartTypedData(cart, verifyingContract, chainID)
	if err != nil {
		return nil, fmt.Errorf("failed to get cart typed data: %w", err)
	}

	// 2. Hash the typed data to get the digest to be signed.
	domainSeparator, err := typedData.HashStruct("EIP712Domain", typedData.Domain.Map())
	if err != nil {
		return nil, fmt.Errorf("failed to hash domain separator: %w", err)
	}
	typedDataHash, err := typedData.HashStruct(typedData.PrimaryType, typedData.Message)
	if err != nil {
		return nil, fmt.Errorf("failed to hash typed data: %w", err)
	}

	// The final hash to sign is keccak256("\x19\x01" + domainSeparator + typedDataHash).
	hashToSign := []byte{0x19, 0x01}
	hashToSign = append(hashToSign, domainSeparator...)
	hashToSign = append(hashToSign, typedDataHash...)
	finalHash := crypto.Keccak256(hashToSign)

	// 3. Sign the final hash with the provided private key.
	signature, err := crypto.Sign(finalHash, privateKey)
	if err != nil {
		return nil, err
	}

	// 4. Adjust the 'V' value of the signature.
	signature[64] += 27

	log.Printf("...Cart signature successful: 0x%x\n", signature)
	return signature, nil
}

// GetCartTypedData constructs and returns the EIP-712 TypedData structure for a Cart.
// This is used both for signing and for verification in tests.
//
// Parameters:
//   - cart: The Cart struct to construct the typed data for.
//   - verifyingContract: The address of the smart contract that will verify the signature.
//   - chainID: The ID of the blockchain where the contract is deployed.
//
// Returns:
//   - The EIP-712 TypedData structure for the cart.
//   - An error if the construction fails.
func GetCartTypedData(cart *types.Cart, verifyingContract common.Address, chainID *big.Int) (apitypes.TypedData, error) {
	typedData := apitypes.TypedData{
		Types: apitypes.Types{
			"EIP712Domain": []apitypes.Type{
				{Name: "name", Type: "string"},
				{Name: "version", Type: "string"},
				{Name: "chainId", Type: "uint256"},
				{Name: "verifyingContract", Type: "address"},
			},
			"CartMandate": []apitypes.Type{
				{Name: "merchant", Type: "address"},
				{Name: "token", Type: "address"},
				{Name: "amount", Type: "uint256"},
			},
		},
		Domain: apitypes.TypedDataDomain{
			Name:              EIP712DomainName,
				Version:           EIP712DomainVersion,
				ChainId:           (*math.HexOrDecimal256)(chainID),
				VerifyingContract: verifyingContract.Hex(),
		},
		Message: apitypes.TypedDataMessage{
			"merchant": cart.Merchant.Hex(),
			"token":    cart.Token.Hex(),
			"amount":   (*math.HexOrDecimal256)(cart.Amount),
		},
		PrimaryType: "CartMandate",
	}
	return typedData, nil
}