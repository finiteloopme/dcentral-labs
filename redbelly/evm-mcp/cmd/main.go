package main

import (
	"github.com/ethereum/go-ethereum/common"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/config"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/evm"

	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/mcp"
	onchain "github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/resources"

	"github.com/finiteloopme/goutils/pkg/log"
	oserr "github.com/finiteloopme/goutils/pkg/v2/os/err"
)

func main() {
	cfg, err := config.ParseFlags()
	oserr.PanicIfError("error parsing flags", err)

	server := mcp.NewServer()

	client := evm.NewClient(cfg.RPCEndpoint, cfg.WebsocketEndpoint, cfg.Signer)

	rwaManager, err := onchain.NewRWAManager(
		client,
		common.HexToAddress(cfg.RWAContractAddress), // Use the parsed address
	)
	log.Infof("Successfully connected to the Asset Manager: %v", cfg.RWAContractAddress)

	// r, err := rwaManager.GetAllAssets(context.Background())
	// fmt.Println(r)
	server.RegisterTool(
		"list-assets",
		"Get all the on chain assets available and managed by the asset manager",
		rwaManager.GetAllAssets,
		map[string]string{},
	)
	stockAsset := onchain.NewStockAsset(client)
	server.RegisterTool(
		"buy-asset",
		"Buy a specific asset on chain using the contract address, stock id, and amount of tokens to use",
		stockAsset.BuyStock,
		map[string]string{"assetId": "Stock Asset ID", "tokenAmount": "Amount of tokens to use to purchase the stock", "stockAssetContractAddress": "Onchain contract address for stocks"},
	)
	stockListener := onchain.NewStockEventListener(client)
	server.RegisterTool(
		"listen-stock-purchase",
		"Listen for onchain events which could indicate an opportunity to purchase some good stocks",
		stockListener.SubscribeToPurchaseHandler,
		map[string]string{"stockAssetContractAddress": "Onchain contract address for stocks"},
	)

	server.Serve()
}
