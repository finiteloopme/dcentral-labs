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
		log.Fatalf("Failed to load configuration: %%v", err)
	}

	// 2. Load artifacts from user's setup
	log.Println("Loading contract addresses and task data...")
	contracts := loadJSON[types.DeployedContracts](cfg.ContractsFile)
	task := loadJSON[types.TaskData](cfg.TaskFile)

	log.Printf("Loaded Facilitator: %%s", contracts.PaymentFacilitator.Hex())
	log.Printf("Loaded Task: %%s", task.Mandate.Task)

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
		log.Fatalf("Failed to connect as agent: %%v", err)
	}

	// 4. Instantiate the PaymentFacilitator contract
	facilitatorContract, err := bindings.NewPaymentFacilitator(contracts.PaymentFacilitator, client)
	if err != nil {
		log.Fatalf("Failed to instantiate facilitator contract: %%v", err)
	}

	// 5. Simulate monitoring
	log.Println("Monitoring for price drop...")
	time.Sleep(3 * time.Second)
	log.Println("...PRICE DROP DETECTED! Fetching cart from merchant...")

	// 6. Fetch the CartMandate from the merchant server.
	// This simulates the agent interacting with a real merchant API.
	resp, err := http.Get(cfg.MerchantServerURL + "/cart")
	if err != nil {
		log.Fatalf("Failed to fetch cart from merchant: %%v", err)
	}
	defer resp.Body.Close()

	var cartResponse struct {
		Merchant common.Address `json:"merchant"`
		Token    common.Address `json:"token"`
		Amount   *big.Int       `json:"amount"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&cartResponse); err != nil {
		log.Fatalf("Failed to decode cart response: %%v", err)
	}

	// We must use the `bindings` generated structs for the actual contract call.
	cart := bindings.PaymentFacilitatorCartMandate{
		Merchant: cartResponse.Merchant,
		Token:    cartResponse.Token,
		Amount:   cartResponse.Amount,
	}

	intent := bindings.PaymentFacilitatorIntentMandate{
		Task:          crypto.Keccak256Hash([]byte(task.Mandate.Task)),
		Token:         task.Mandate.Token,
		MaxPrice:      task.Mandate.MaxPrice,
		Expires:       task.Mandate.Expires,
		ProxyContract: task.Mandate.ProxyContract,
		Nonce:         task.Mandate.Nonce,
	}

	// 7. Execute the purchase by calling the proxy
	// The AGENT pays the gas for this transaction.
	intentJSON, _ := json.MarshalIndent(struct {
		Task          string
		Token         common.Address
		MaxPrice      *big.Int
		Expires       *big.Int
		ProxyContract common.Address
		Nonce         *big.Int
	}{
		Task:          task.Mandate.Task,
		Token:         intent.Token,
		MaxPrice:      intent.MaxPrice,
		Expires:       intent.Expires,
		ProxyContract: intent.ProxyContract,
		Nonce:         intent.Nonce,
	}, "", "  ")
	cartJSON, _ := json.MarshalIndent(cart, "", "  ")
	log.Printf("Intent: %%s", string(intentJSON))
	log.Printf("Cart: %%s", string(cartJSON))
	log.Println("Agent is executing purchase on user's behalf...")
	tx, err := facilitatorContract.ExecutePurchase(agentAuth, intent, cart, task.Signature)
	if err != nil {
		if tx != nil {
			log.Printf("Transaction hash: %%s", tx.Hash().Hex())
		}
		log.Fatalf("Failed to execute purchase: %%v", err)
	}

	// Wait for the transaction to be mined
	receipt, err := bind.WaitMined(ctx, client, tx)
	if err != nil {
		log.Fatalf("Failed to wait for execution tx: %%v", err)
	}

	if receipt.Status == 0 {
		log.Fatalf("Transaction failed (reverted)!")
	}

	log.Printf("...Purchase successful! Tx: %%s", receipt.TxHash.Hex())
	log.Printf("Merchant (%%s) has been paid 49 tUSDC.", cfg.MerchantAddress)
	log.Println("--- (PHASE 2) AGENT EXECUTION COMPLETE ---")
}

// loadJSON is a generic helper utility to read a JSON file and unmarshal it into a given struct type.
func loadJSON[T any](filePath string) T {
	var data T
	file, err := os.ReadFile(filePath)
	if err != nil {
		log.Fatalf("Failed to read JSON file %%s: %%v", filePath, err)
	}
	if err := json.Unmarshal(file, &data); err != nil {
		log.Fatalf("Failed to unmarshal JSON from %%s: %%v", filePath, err)
	}
	return data
}