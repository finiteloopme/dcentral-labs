// Package signing provides functions for creating EIP-712 compliant signatures.
package signing

import (
	"crypto/ecdsa"
	"log"
	"math/big"

	"delegated-agent-demo/pkg/types"

	"github.com/ethereum/go-ethereum/common/math"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/signer/core/apitypes"
)

// EIP712DomainName is the `name` in the EIP712 Domain constructor.
// This MUST match the name in the `PaymentFacilitator.sol` constructor for signatures to be valid.
const EIP712DomainName = "PaymentFacilitator"

// EIP712DomainVersion is the `version` in the EIP712 Domain constructor.
// This MUST match the version in the `AgentProxy.sol` constructor.
const EIP712DomainVersion = "1"

// SignIntentMandate signs an IntentMandate struct according to the EIP-712 standard.
// It constructs the typed data, hashes it, signs the hash, and returns the signature.
// The output signature is a 65-byte array in [R || S || V] format.
func SignIntentMandate(
	mandate *types.IntentMandate,
	privateKey *ecdsa.PrivateKey,
	chainID *big.Int,
) ([]byte, error) {

	log.Println("Signing EIP-712 IntentMandate...")

	// 1. Define the EIP-712 TypedData structure.
	// This structure must EXACTLY MATCH the layout and types defined in the
	// AgentProxy.sol smart contract, including the EIP712Domain and the IntentMandate struct.
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
				{Name: "proxyContract", Type: "address"},
				{Name: "nonce", Type: "uint256"},
			},
		},
		// Domain is the EIP-712 domain separator data. It ensures that a signature
		// is unique to a specific domain (e.g., a specific contract on a specific chain).
		Domain: apitypes.TypedDataDomain{
			Name:              EIP712DomainName,
			Version:           EIP712DomainVersion,
			ChainId:           (*math.HexOrDecimal256)(chainID),
			VerifyingContract: mandate.ProxyContract.Hex(),
		},
		// Message is the actual data to be signed.
		Message: apitypes.TypedDataMessage{
			// The `task` field is a string in the Go struct, but the contract expects a bytes32 hash.
			// We hash it here to match the contract's expectation.
			"task":          crypto.Keccak256Hash([]byte(mandate.Task)),
			"token":         mandate.Token.Hex(),
			"maxPrice":      (*math.HexOrDecimal256)(mandate.MaxPrice),
			"expires":       (*math.HexOrDecimal256)(mandate.Expires),
			"proxyContract": mandate.ProxyContract.Hex(),
			"nonce":         (*math.HexOrDecimal256)(mandate.Nonce),
		},
		PrimaryType: "IntentMandate",
	}

	// 2. Hash the typed data struct using the EIP-712 standard hashing algorithm.
	domainSeparator, err := typedData.HashStruct("EIP712Domain", typedData.Domain.Map())
	if err != nil {
		return nil, err
	}
	typedDataHash, err := typedData.HashStruct(typedData.PrimaryType, typedData.Message)
	if err != nil {
		return nil, err
	}
	log.Printf("Typed data hash: 0x%%x", typedDataHash)

	// 3. Construct the final digest to be signed, as per EIP-191.
	// This involves prefixing the packed domain separator and typed data hash
	// with `\x19\x01`.
	hashToSign := []byte{0x19, 0x01}
	hashToSign = append(hashToSign, domainSeparator...)
	hashToSign = append(hashToSign, typedDataHash...)
	finalHash := crypto.Keccak256(hashToSign)

	// 4. Sign the final hash with the provided private key.
	signature, err := crypto.Sign(finalHash, privateKey)
	if err != nil {
		return nil, err
	}

	// 5. Adjust the 'V' value of the signature.
	// The `crypto.Sign` function returns V as 0 or 1, but Ethereum RPCs expect it
	// to be 27 or 28. We add 27 to the value to make it compliant.
	signature[64] += 27

	log.Printf("...Signature successful: 0x%%x\n", signature)
	return signature, nil
}
