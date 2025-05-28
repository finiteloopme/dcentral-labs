package evm

import (
	"crypto/ecdsa"
	"fmt"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	oserr "github.com/finiteloopme/goutils/pkg/v2/os/err"
)

// type HelloArguments struct {
// 	Submitter string `json:"submitter" jsonschema:"required,description=The name of the thing calling this tool (openai or google or claude etc)'"`
// }

type Signer struct {
	Address    *common.Address   `json:"address" jsonschema:"optional,description=The address of the signer calling this tool"`
	PublicKey  *ecdsa.PublicKey  `json:"public_key" jsonschema:"optional,description=The pubkey of the signer calling this tool"`
	PrivateKey *ecdsa.PrivateKey `json:"private_key" jsonschema:"optional,description=The private key of the signer calling this tool"`
}

type SignerAddress struct {
	Address string `json:"address" jsonschema:"optional,description=The address of the signer calling this tool"`
}

func NewSigner(privatekey string) *Signer {
	privateKey, err := crypto.HexToECDSA(privatekey)
	oserr.PanicIfError("Unable to parse private key for the signer.", err)

	return PrivateKeyToSigner(privateKey)
}

func PrivateKeyToSigner(privateKey *ecdsa.PrivateKey) *Signer {
	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		oserr.PanicIfError("Unable to parse public key for the signer.", fmt.Errorf("error casting public key to ECDSA"))
	}
	address := crypto.PubkeyToAddress(*publicKeyECDSA)
	return &Signer{
		PublicKey:  publicKeyECDSA,
		PrivateKey: privateKey,
		Address:    &address,
	}
}
