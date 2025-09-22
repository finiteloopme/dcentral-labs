// This package contains a simple merchant server for the demo.
package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math/big"
	"net/http"
	"os"

	"delegated-agent-demo/pkg/config"
	"delegated-agent-demo/pkg/signing"
	"delegated-agent-demo/pkg/types"

	"github.com/ethereum/go-ethereum/crypto"
)

// jsonError is a helper to create a consistent JSON error response.
func jsonError(w http.ResponseWriter, message string, code int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	// Ignores error on Encode, as it's unlikely to fail and we can't send another error.
	_ = json.NewEncoder(w).Encode(map[string]string{"error": message})
}

// healthzHandler provides a simple health check endpoint.
func healthzHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

// cartHandler processes requests for the signed shopping cart.
func cartHandler(w http.ResponseWriter, r *http.Request) {
	log.Println("Received request for /cart")
	cfg, err := config.LoadConfig()
	if err != nil {
		jsonError(w, fmt.Sprintf("failed to load config: %v", err), http.StatusInternalServerError)
		return
	}

	contracts, err := loadJSON[types.DeployedContracts](cfg.ContractsFile)
	if err != nil {
		jsonError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	task, err := loadJSON[types.TaskData](cfg.TaskFile)
	if err != nil {
		jsonError(w, err.Error(), http.StatusInternalServerError)
		return
	}

	merchantKey, err := crypto.HexToECDSA(cfg.MerchantPrivateKey)
	if err != nil {
		jsonError(w, "failed to load merchant private key", http.StatusInternalServerError)
		return
	}

	// Derive the merchant address from the private key to ensure consistency.
	merchantAddress := crypto.PubkeyToAddress(merchantKey.PublicKey)

	cart := &types.Cart{
		Merchant: merchantAddress,
		Token:    contracts.TokenUSDC,
		Amount:   new(big.Int).Mul(big.NewInt(49), big.NewInt(1e18)), // 49 USDC
	}

	chainID := big.NewInt(cfg.ChainID)
	log.Printf("Token address from contracts.json: %s", contracts.TokenUSDC.Hex())
	log.Printf("Intent used for signing: %+v", task.Mandate)
	log.Printf("Cart to be signed: %+v", cart)
	log.Printf("Signing cart with chainID: %d and verifyingContract: %s", chainID, contracts.PaymentFacilitator.Hex())
	signature, err := signing.SignCartMandate(cart, contracts.PaymentFacilitator, merchantKey, chainID)
	if err != nil {
		jsonError(w, fmt.Sprintf("failed to sign cart: %v", err), http.StatusInternalServerError)
		return
	}

	signedCart := types.SignedCart{
		Cart:      cart,
		Signature: signature,
	}

	log.Printf("Serving signed cart details for merchant: %s", cart.Merchant.Hex())
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	if err := json.NewEncoder(w).Encode(signedCart); err != nil {
		log.Printf("Error encoding signed cart response: %v", err)
	}
}

func main() {
	log.Println("--- MERCHANT SERVER STARTING ---")

	http.HandleFunc("/cart", cartHandler)
	http.HandleFunc("/healthz", healthzHandler)

	log.Println("Merchant server listening on :8081")
	if err := http.ListenAndServe(":8081", nil); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

// loadJSON is a generic helper utility to read a JSON file and unmarshal it.
// It now returns an error instead of fatally logging.
func loadJSON[T any](filePath string) (T, error) {
	var data T
	file, err := os.ReadFile(filePath)
	if err != nil {
		return data, fmt.Errorf("failed to read JSON file %s: %w", filePath, err)
	}
	if err := json.Unmarshal(file, &data); err != nil {
		return data, fmt.Errorf("failed to unmarshal JSON from %s: %w", filePath, err)
	}
	return data, nil
}
