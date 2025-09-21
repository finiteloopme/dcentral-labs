// Package chain provides helper functions for interacting with the Ethereum blockchain.
package chain

import (
	"context"
	"crypto/ecdsa"
	"log"
	"math/big"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

// Config holds the necessary configuration for connecting to an Ethereum client
// and authenticating a wallet.
type Config struct {
	// RPCUrl is the URL of the Ethereum JSON-RPC endpoint.
	RPCUrl string
	// PrivateKey is the hexadecimal representation of the account's private key.
	PrivateKey string
	// ChainID is the ID of the target Ethereum chain.
	ChainID *big.Int
}

// GetClientAndAuth establishes a connection to an Ethereum node and prepares a
// transaction signer (TransactOpts) for a specific account.
// It returns an ethclient instance and a TransactOpts object ready for use.
func GetClientAndAuth(ctx context.Context, cfg Config) (*ethclient.Client, *bind.TransactOpts, error) {
	// Dial the Ethereum client using the provided RPC URL.
	client, err := ethclient.DialContext(ctx, cfg.RPCUrl)
	if err != nil {
		return nil, nil, err
	}

	// Decode the hexadecimal private key into an ECDSA private key object.
	privateKey, err := crypto.HexToECDSA(cfg.PrivateKey)
	if err != nil {
		return nil, nil, err
	}

	// Create a new transaction signer (TransactOpts) from the private key and chain ID.
	// This object is used to sign and send transactions to the network.
	auth, err := bind.NewKeyedTransactorWithChainID(privateKey, cfg.ChainID)
	if err != nil {
		return nil, nil, err
	}

	// Derive the public key and address from the private key for logging purposes.
	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatal("error casting public key to ECDSA")
	}
	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)
	log.Printf("Loaded wallet for address: %s", fromAddress.Hex())

	return client, auth, nil
}
