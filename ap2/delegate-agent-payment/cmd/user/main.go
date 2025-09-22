// This package contains the user setup script.
// This script simulates the actions a user would take once to set up
// their AgentProxy contract and authorize it for future delegated payments.
package main

import (
	"context"
	"encoding/json"
	"log"
	"math/big"
	"math/rand"
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
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// 2. Connect to the blockchain as the USER.
	// This uses the `userPrivateKey` from the config.
	ctx := context.Background()
	userCfg := chain.Config{
		RPCUrl:     cfg.RPCUrl,
		PrivateKey: cfg.UserPrivateKey,
		ChainID:    big.NewInt(cfg.ChainID),
	}
	client, userAuth, err := chain.GetClientAndAuth(ctx, userCfg)
	if err != nil {
		log.Fatalf("Failed to connect as user: %v", err)
	}
	log.Printf("Loaded wallet for address: %s", userAuth.From.Hex())

	// 3. Deploy the contracts.
	// The user pays the gas for these deployments.
	log.Println("Deploying contracts...")
	usdcAddress, tx, _, err := bindings.DeployTokenUSDC(userAuth, client, big.NewInt(0))
	if err != nil {
		log.Fatalf("Failed to deploy TokenUSDC contract: %v", err)
	}
	log.Printf("TokenUSDC deployed at: %s (tx: %s)", usdcAddress.Hex(), tx.Hash().Hex())

	// Wait for the transaction to be mined to ensure the contract is available.
	_, err = bind.WaitMined(ctx, client, tx)
	if err != nil {
		log.Fatalf("Failed to wait for TokenUSDC deployment: %v", err)
	}

	facilitatorAddress, tx, _, err := bindings.DeployPaymentFacilitator(userAuth, client)
	if err != nil {
		log.Fatalf("Failed to deploy PaymentFacilitator contract: %v", err)
	}
	log.Printf("PaymentFacilitator deployed at: %s (tx: %s)", facilitatorAddress.Hex(), tx.Hash().Hex())

	_, err = bind.WaitMined(ctx, client, tx)
	if err != nil {
		log.Fatalf("Failed to wait for PaymentFacilitator deployment: %v", err)
	}

	// 4. Mint some mock USDC for the user.
	usdcContract, err := bindings.NewTokenUSDC(usdcAddress, client)
	if err != nil {
		log.Fatalf("Failed to instantiate USDC contract: %v", err)
	}
	log.Println("Minting 1000 tUSDC for user...")
	tx, err = usdcContract.Mint(userAuth, userAuth.From, new(big.Int).Mul(big.NewInt(1000), big.NewInt(1e18)))
	if err != nil {
		log.Fatalf("Failed to mint tokens: %v", err)
	}
	_, err = bind.WaitMined(ctx, client, tx)
	if err != nil {
		log.Fatalf("Failed to wait for mint tx: %v", err)
	}
	log.Println("...Mint successful!")

	// 5. Approve the PaymentFacilitator to spend the user's USDC.
	// This is the crucial on-chain step that gives the proxy permission.
	allowance := new(big.Int).Mul(big.NewInt(50), big.NewInt(1e18)) // 50 USDC
	log.Printf("Approving PaymentFacilitator (%s) to spend %d tUSDC...", facilitatorAddress.Hex(), allowance)
	tx, err = usdcContract.Approve(userAuth, facilitatorAddress, allowance)
	if err != nil {
		log.Fatalf("Failed to approve PaymentFacilitator: %v", err)
	}
	_, err = bind.WaitMined(ctx, client, tx)
	if err != nil {
		log.Fatalf("Failed to wait for approval tx: %v", err)
	}
	log.Printf("...Approval successful! (tx: %s)", tx.Hash().Hex())

	// 6. Define the user's intent off-chain.
	// This struct contains the rules the agent must follow.
	mandate := &types.IntentMandate{
		Task:          "Buy 'Blue Widget' if price is good",
		Token:         usdcAddress,
		MaxPrice:      allowance, // Max price is the same as the allowance
		Expires:       big.NewInt(time.Now().Add(24 * time.Hour).Unix()),
		Nonce:         big.NewInt(rand.Int63()), // Use a random nonce for demo purposes
	}

	// 7. Sign the intent using EIP-712.
	// This signature is the agent's "permission slip".
	userPrivateKey, err := crypto.HexToECDSA(cfg.UserPrivateKey)
	if err != nil {
		log.Fatalf("Failed to load user private key: %v", err)
	}
	signature, err := signing.SignIntentMandate(mandate, facilitatorAddress, userPrivateKey, big.NewInt(cfg.ChainID))
	if err != nil {
		log.Fatalf("Failed to sign intent mandate: %v", err)
	}

	// 8. Save the deployed contract addresses and the signed task data.
	// The agent will load these files to execute the task.
	log.Println("Saving deployment addresses and task data...")
	saveJSON(cfg.ContractsFile, types.DeployedContracts{
		TokenUSDC:          usdcAddress,
		PaymentFacilitator: facilitatorAddress,
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
		log.Fatalf("Failed to marshal JSON for %s: %v", filePath, err)
	}

	if err := os.WriteFile(filePath, file, 0644); err != nil {
		log.Fatalf("Failed to write JSON to %s: %v", filePath, err)
	}
}
