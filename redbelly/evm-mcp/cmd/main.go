package main

import (
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/config"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/evm"

	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/mcp"
	onchain "github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/resources"

	oserr "github.com/finiteloopme/goutils/pkg/v2/os/err"
)

func main() {
	cfg, err := config.ParseFlags()
	oserr.PanicIfError("error parsing flags", err)

	server := mcp.NewServer()

	client := evm.NewClient(cfg.RPCEndpoint, cfg.WebsocketEndpoint, cfg.Signer)

	// rwaManager, err := onchain.NewRWAManager(
	// 	client,
	// 	common.HexToAddress(cfg.RWAContractAddress), // Use the parsed address
	// )
	// log.Infof("Successfully connected to the Asset Manager: %v", cfg.RWAContractAddress)
	assetAgg := onchain.NewAssetAggretator(client, cfg)
	// bonds := onchain.NewBondContract(client, cfg.BondContractAddress)
	// stocks := onchain.NewStockContract(client, cfg.StockContractAddress)

	// server.RegisterTool(
	// 	"greet-user",
	// 	"Welcome the user. User can use this way to set their name, private key, and investment risk profile",
	// 	rwaManager.RegisterUser,
	// 	map[string]string{
	// 		"userName":    "Name of user.  Used to greet the user",
	// 		"signer":      "Private key for the user.  Used to sign transactions on behalf of the user.  NEVER SHARE THIS WITH ANYONE, including playing it back to the user",
	// 		"riskProfile": "Risk Profile (low, medium, or high)",
	// 	},
	// )
	server.RegisterTool(
		"list-assets",
		"Get all the on chain assets available and managed by the asset manager",
		assetAgg.GetAllAssets,
		// bonds.GetAllAssets,
		// stocks.GetAllAssets,
		map[string]string{},
	)
	server.RegisterTool(
		"buy-asset",
		"Buy a specific asset on chain using the specific amounts of token",
		assetAgg.Buy,
		map[string]string{
			"assetType":   "Type of the asset (stock, bond, property or alternate)",
			"assetId":     "Asset ID to purchase",
			"tokenAmount": "Amount of tokens to use to purchase the stock",
		},
	)
	server.RegisterTool(
		"sell-asset",
		"Sell all of the user's position for a specific asset on chain",
		assetAgg.Sell,
		map[string]string{
			"assetType":   "Type of the asset (stock, bond, property or alternate)",
			"assetId":     "Asset ID to purchase",
			"tokenAmount": "Amount of tokens to use to purchase the stock",
		},
	)
	server.RegisterTool(
		"list-user-owned-assets",
		"Get the assets owned specifically by the user.",
		assetAgg.GetMyAssets,
		// map[string]string{"userAddress": "Hex representation of the user's wallet address"},
		map[string]string{},
	)
	// server.RegisterTool(
	// 	"list-assets",
	// 	"Get all the on chain assets available and managed by the asset manager",
	// 	rwaManager.GetAllAssets,
	// 	map[string]string{"stockAssetContractAddress": "Onchain contract address for stocks"},
	// )
	// server.RegisterTool(
	// 	"set-risk-profile",
	// 	"Set the investment risk profile for the user's.  This will provide guidance to the agent on the mix of assets (percentage wise) in the portfolio",
	// 	rwaManager.SetRiskProfile,
	// 	map[string]string{"riskProfile": "Risk Profile (low, medium, or high)"},
	// )
	// stockAsset := onchain.NewStockAsset(client)
	// server.RegisterTool(
	// 	"buy-asset",
	// 	"Buy a specific asset on chain using the contract address, stock id, and amount of tokens to use",
	// 	stockAsset.BuyStock,
	// 	map[string]string{"assetId": "Stock Asset ID", "tokenAmount": "Amount of tokens to use to purchase the stock", "stockAssetContractAddress": "Onchain contract address for stocks"},
	// )
	// server.RegisterTool(
	// 	"get-user-owned-assets",
	// 	"Get the assets owned specifically by the user.",
	// 	stockAsset.RetrieveMyStocks,
	// 	// map[string]string{"userAddress": "Hex representation of the user's wallet address"},
	// 	map[string]string{"stockAssetContractAddress": "Contract address for the stocks"},
	// )
	// stockListener := onchain.NewStockEventListener(client)
	// server.RegisterTool(
	// 	"register-stock-purchase",
	// 	"Listen for onchain events to initiate an automatic purchase of stocks. Great for catching the initial offers",
	// 	stockListener.SubscribeToPurchaseHandler,
	// 	map[string]string{"stockAssetContractAddress": "Onchain contract address for stocks", "purchaseAmount": "Default amount used to automatically purchase stocks"},
	// )

	server.Serve()
}
