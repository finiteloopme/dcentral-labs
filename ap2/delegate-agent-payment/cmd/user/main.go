// This package contains the user setup script.
// This script simulates the actions a user would take once to set up
// their AgentProxy contract and authorize it for future delegated payments.
package main

import (
	"context"
	"crypto/rand"
	"encoding/json"
	"log"
	"math/big"
	"os"
	"time"

	"delegated-agent-demo/pkg/chain"
	"delegated-agent-demo/pkg/chain/bindings"
	"delegated-agent-demo/pkg/config"
	"delegated-agent-demo/pkg/signing"
	"delegated-agent-demo/pkg/types"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/crypto"
)

// main is the entry point for the user setup script.
func main() {
	log.Println("--- (PHASE 1) USER SETUP STARTING ---")

	// 1. Load configuration from config.toml and environment variables.
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf("Failed to load configuration: %%v", err)
	}

	// 2. Connect to the blockchain as the USER.
	// It uses the user's private key to create a transaction signer.
	ctx := context.Background()
	userCfg := chain.Config{
		RPCUrl:     cfg.RPCUrl,
		PrivateKey: cfg.UserPrivateKey,
		ChainID:    big.NewInt(cfg.ChainID),
	}
	client, userAuth, err := chain.GetClientAndAuth(ctx, userCfg)
	if err != nil {
		log.Fatalf("Failed to connect as user: %%v", err)
	}

	// 3. Deploy the TokenUSDC contract.
	// We mint 1,000 USDC (with 18 decimals for this mock) to the user upon deployment.
	initialSupply := new(big.Int).Mul(big.NewInt(1000), big.NewInt(1e18))
	usdcAddr, tx, usdcContract, err := bindings.DeployTokenUSDC(userAuth, client, initialSupply)
	if err != nil {
		log.Fatalf("Failed to deploy TokenUSDC: %%v", err)
	}
	log.Printf("TokenUSDC deployed at: %%s (tx: %%s)", usdcAddr.Hex(), tx.Hash().Hex())

	// Wait for the deployment transaction to be mined.
	_, err = bind.WaitMined(ctx, client, tx)
	if err != nil {
		log.Fatalf("Failed to wait for TokenUSDC deployment: %%v", err)
	}

	// 4. Deploy the PaymentFacilitator contract.
	// The `msg.sender` for this transaction (the user) will become the `owner`.
	facilitatorAddr, tx, _, err := bindings.DeployPaymentFacilitator(userAuth, client)
	if err != nil {
		log.Fatalf("Failed to deploy PaymentFacilitator: %%v", err)
	}
	log.Printf("PaymentFacilitator deployed at: %%s (tx: %%s)", facilitatorAddr.Hex(), tx.Hash().Hex())

	// Wait for the deployment transaction to be mined.
	_, err = bind.WaitMined(ctx, client, tx)
	if err != nil {
		log.Fatalf("Failed to wait for PaymentFacilitator deployment: %%v", err)
	}

	// 5. Send the on-chain `approve` transaction.
	// This is the crucial on-chain pre-approval step that allows the PaymentFacilitator
	// contract to spend a certain amount of the user's USDC.
	approveAmount := new(big.Int).Mul(big.NewInt(50), big.NewInt(1e18)) // 50 USDC
	log.Printf("Approving PaymentFacilitator (%%s) to spend %%d tUSDC...", facilitatorAddr.Hex(), approveAmount)

	tx, err = usdcContract.Approve(userAuth, facilitatorAddr, approveAmount)
	if err != nil {
		log.Fatalf("Failed to approve facilitator: %%v", err)
	}
	_, err = bind.WaitMined(ctx, client, tx)
	if err != nil {
		log.Fatalf("Failed to wait for approval: %%v", err)
	}
	log.Printf("...Approval successful! (tx: %%s)", tx.Hash().Hex())

	// 6. Create and Sign the `IntentMandate` off-chain.
	// This serves as the "permission slip" for the agent, defining the rules
	// under which it can execute a payment on the user's behalf.

	// Generate a secure random nonce for replay protection.
	nonce, err := rand.Int(rand.Reader, new(big.Int).Lsh(big.NewInt(1), 128))
	if err != nil {
		log.Fatalf("Failed to generate nonce: %%v", err)
	}

	mandate := &types.IntentMandate{
		Task:          "Buy 'Blue Widget' if price is good",
		Token:         usdcAddr,
		MaxPrice:      approveAmount,                                     // Max price is 50 USDC
		Expires:       big.NewInt(time.Now().Add(24 * time.Hour).Unix()), // Valid for 24 hours
		ProxyContract: facilitatorAddr,
		Nonce:         nonce,
	}

	// Sign the mandate using the EIP-712 standard.
	userKey, err := crypto.HexToECDSA(cfg.UserPrivateKey)
	if err != nil {
		log.Fatalf("Failed to encode private key (hex) to ECDSA: %%v", err)
	}
	signature, err := signing.SignIntentMandate(mandate, userKey, userCfg.ChainID)
	if err != nil {
		log.Fatalf("Failed to sign intent mandate: %%v", err)
	}

	// 7. Save the generated artifacts to files for the agent to use.
	// This includes the deployed contract addresses and the signed task data.
	log.Println("Saving deployment addresses and task data...")
	saveJSON(cfg.ContractsFile, types.DeployedContracts{
		TokenUSDC:          usdcAddr,
		PaymentFacilitator: facilitatorAddr,
	})
	saveJSON(cfg.TaskFile, types.TaskData{
		Mandate:   mandate,
		Signature: signature,
	})

	log.Println("--- (PHASE 1) USER SETUP COMPLETE ---")
}

// saveJSON is a helper utility to marshal a struct into indented JSON and write it to a file.
func saveJSON(filePath string, data interface{}) {
	file, err := json.MarshalIndent(data, "", "  ")
	if err != nil {
		log.Fatalf("Failed to marshal JSON: %%v", err)
	}
	if err := os.WriteFile(filePath, file, 0644); err != nil {
		log.Fatalf("Failed to write JSON file: %%v", err)
	}
}
