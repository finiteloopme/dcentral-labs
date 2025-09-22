// This package contains the agent execution script.
// This script simulates the actions an autonomous agent or facilitator would take
// to execute a payment on behalf of a user, using the user's pre-approved intent.
package main

import (
	"context"
	"encoding/json"
	"log"
	"math/big"
	"net/http"
	"os"
	"time"

	"delegated-agent-demo/pkg/chain"
	"delegated-agent-demo/pkg/chain/bindings"
	"delegated-agent-demo/pkg/config"
	"delegated-agent-demo/pkg/types"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
)

// main is the entry point for the agent execution script.
func main() {
	log.Println("--- (PHASE 2) AGENT EXECUTION STARTING ---")
	log.Println("...User is now 'asleep'...")

	// 1. Load configuration
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// 2. Load artifacts from user's setup
	log.Println("Loading contract addresses and task data...")
	contracts := loadJSON[types.DeployedContracts](cfg.ContractsFile)
	task := loadJSON[types.TaskData](cfg.TaskFile)

	log.Printf("Loaded Facilitator: %s", contracts.PaymentFacilitator.Hex())
	log.Printf("Loaded Task: %s", task.Mandate.Task)

	// 3. Connect to the blockchain as the AGENT (facilitator)
	// Notice we use the `agentPrivateKey` here.
	ctx := context.Background()
	agentCfg := chain.Config{
		RPCUrl:     cfg.RPCUrl,
		PrivateKey: cfg.AgentPrivateKey,
		ChainID:    big.NewInt(cfg.ChainID),
	}
	client, agentAuth, err := chain.GetClientAndAuth(ctx, agentCfg)
	if err != nil {
		log.Fatalf("Failed to connect as agent: %v", err)
	}

	// 4. Instantiate the PaymentFacilitator contract
	facilitatorContract, err := bindings.NewPaymentFacilitator(contracts.PaymentFacilitator, client)
	if err != nil {
		log.Fatalf("Failed to instantiate facilitator contract: %v", err)
	}

	// 5. Wait for the merchant server to be ready.
	waitForMerchant(cfg.MerchantServerURL)

	// 6. Simulate monitoring
	log.Println("Monitoring for price drop...")
	time.Sleep(3 * time.Second)
	log.Println("...PRICE DROP DETECTED! Fetching cart from merchant...")

	// 7. Fetch the CartMandate from the merchant server.
	// This simulates the agent interacting with a real merchant API.
	resp, err := http.Get(cfg.MerchantServerURL + "/cart")
	if err != nil {
		log.Fatalf("Failed to fetch cart from merchant: %v", err)
	}
	defer resp.Body.Close()

	// Handle non-200 responses
	if resp.StatusCode != http.StatusOK {
		var errorResponse map[string]string
		if err := json.NewDecoder(resp.Body).Decode(&errorResponse); err != nil {
			log.Fatalf("Received non-OK status from merchant, but failed to decode error response: %v", err)
		}
		log.Fatalf("Merchant returned an error: %s", errorResponse["error"])
	}

	var cartResponse types.SignedCart
	if err := json.NewDecoder(resp.Body).Decode(&cartResponse); err != nil {
		log.Fatalf("Failed to decode successful cart response: %v", err)
	}

	// We must use the `bindings` generated structs for the actual contract call.
	cart := bindings.PaymentFacilitatorCartMandate{
		Merchant: cartResponse.Cart.Merchant,
		Token:    cartResponse.Cart.Token,
		Amount:   cartResponse.Cart.Amount,
	}

	intent := bindings.PaymentFacilitatorIntentMandate{
		Task:          crypto.Keccak256Hash([]byte(task.Mandate.Task)),
		Token:         task.Mandate.Token,
		MaxPrice:      task.Mandate.MaxPrice,
		Expires:       task.Mandate.Expires,
		Nonce:         task.Mandate.Nonce,
	}

	// 7. Execute the purchase by calling the proxy
	// The AGENT pays the gas for this transaction.
	intentJSON, _ := json.MarshalIndent(struct {
		Task          string
		Token         common.Address
		MaxPrice      *big.Int
		Expires       *big.Int
		Nonce         *big.Int
	}{
		Task:          task.Mandate.Task,
		Token:         intent.Token,
		MaxPrice:      intent.MaxPrice,
		Expires:       intent.Expires,
		Nonce:         intent.Nonce,
	}, "", "  ")
	cartJSON, _ := json.MarshalIndent(cart, "", "  ")
	log.Printf("Intent: %s", string(intentJSON))
	log.Printf("Cart: %s", string(cartJSON))
	log.Println("Agent is executing purchase on user's behalf...")
	log.Printf("Token address from contracts.json: %s", contracts.TokenUSDC.Hex())
	log.Printf("Intent to be executed: %+v", intent)
	log.Printf("Cart to be executed: %+v", cart)
	log.Printf("Verifying cart signature with chainID: %d and verifyingContract: %s", cfg.ChainID, contracts.PaymentFacilitator.Hex())
	tx, err := facilitatorContract.ExecutePurchase(agentAuth, intent, cart, task.Signature, cartResponse.Signature)
	if err != nil {
		if tx != nil {
			log.Printf("Transaction hash: %s", tx.Hash().Hex())
		}
		log.Fatalf("Failed to execute purchase: %v", err)
	}

	// Wait for the transaction to be mined
	receipt, err := bind.WaitMined(ctx, client, tx)
	if err != nil {
		log.Fatalf("Failed to wait for execution tx: %v", err)
	}

	if receipt.Status == 0 {
		log.Fatalf("Transaction failed (reverted)!")
	}

	log.Printf("...Purchase successful! Tx: %s", receipt.TxHash.Hex())
	log.Printf("Merchant (%s) has been paid 49 tUSDC.", cfg.MerchantAddress)
	log.Println("--- (PHASE 2) AGENT EXECUTION COMPLETE ---")
}

func loadJSON[T any](filePath string) T {
	var data T
	file, err := os.ReadFile(filePath)
	if err != nil {
		log.Fatalf("Failed to read JSON file %s: %v", filePath, err)
	}
	if err := json.Unmarshal(file, &data); err != nil {
		log.Fatalf("Failed to unmarshal JSON from %s: %v", filePath, err)
	}
	return data
}

// waitForMerchant polls the merchant's /healthz endpoint until it gets a 200 OK.
func waitForMerchant(baseURL string) {
	log.Println("Waiting for merchant server to be ready...")
	for i := 0; i < 10; i++ { // Poll for a maximum of 10 seconds
		resp, err := http.Get(baseURL + "/healthz")
		if err == nil && resp.StatusCode == http.StatusOK {
			log.Println("...Merchant server is ready.")
			resp.Body.Close()
			return
		}
		if resp != nil {
			resp.Body.Close()
		}
		time.Sleep(1 * time.Second)
	}
	log.Fatalf("Merchant server did not become ready in time.")
}