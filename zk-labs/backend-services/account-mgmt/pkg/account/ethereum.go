package account

import (
	"crypto/ecdsa"
	"fmt"

	"github.com/ethereum/go-ethereum/common/hexutil"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/finiteloopme/goutils/pkg/log"
)

func CreateEthAccount() (privKey, pubKey, ethAddress string) {
	privateKey, err := crypto.GenerateKey()
	if err != nil {
		log.Fatal(err)
	}

	privateKeyBytes := crypto.FromECDSA(privateKey)
	// log.Info(fmt.Sprintf("SAVE BUT DO NOT SHARE THIS (Private Key): %v", hexutil.Encode(privateKeyBytes)))

	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatal(fmt.Errorf("cannot assert type: publicKey is not of type *ecdsa.PublicKey"))
	}

	publicKeyBytes := crypto.FromECDSAPub(publicKeyECDSA)
	// log.Info(fmt.Sprintf("Public Key: %v", hexutil.Encode(publicKeyBytes)))

	address := crypto.PubkeyToAddress(*publicKeyECDSA).Hex()
	// log.Info(fmt.Sprintf("Address: %v", address))
	return string(privateKeyBytes), hexutil.Encode(publicKeyBytes), address
}
