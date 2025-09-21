// This package contains a simple merchant server for the demo.
package main

import (
	"encoding/json"
	"log"
	"math/big"
	"net/http"
	"os"

	"delegated-agent-demo/pkg/config"
	"delegated-agent-demo/pkg/types"

	"github.com/ethereum/go-ethereum/common"
)

// Cart represents the merchant's bill for the agent.
type Cart struct {
	Merchant common.Address `json:"merchant"`
	Token    common.Address `json:"token"`
	Amount   *big.Int       `json:"amount"`
}

func main() {
	log.Println("--- MERCHANT SERVER STARTING ---")

	// The handler function for the /cart endpoint.
	cartHandler := func(w http.ResponseWriter, r *http.Request) {
		// For this demo, we load the config and deployed contract addresses
		// on each request to get the correct merchant and token addresses.
		cfg, err := config.LoadConfig()
		if err != nil {
			http.Error(w, "Failed to load config", http.StatusInternalServerError)
			return
		}
		contracts := loadJSON[types.DeployedContracts](cfg.ContractsFile)

		// Create the cart with the payment details.
		// In a real application, this would be based on a user's shopping session.
		cart := Cart{
			Merchant: common.HexToAddress(cfg.MerchantAddress),
			Token:    contracts.TokenUSDC,
			Amount:   new(big.Int).Mul(big.NewInt(49), big.NewInt(1e18)), // 49 USDC
		}

		log.Printf("Serving cart details: %+v", cart)

		w.Header().Set("Content-Type", "application/json")
		if err := json.NewEncoder(w).Encode(cart); err != nil {
			http.Error(w, "Failed to encode cart JSON", http.StatusInternalServerError)
		}
	}

	http.HandleFunc("/cart", cartHandler)

	// Start the server.
	log.Println("Merchant server listening on :8081")
	if err := http.ListenAndServe(":8081", nil); err != nil {
		log.Fatalf("Failed to start server: %%v", err)
	}
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
