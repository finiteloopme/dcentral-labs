package main

import (
	"context"
	"fmt"

	"github.com/ethereum/go-ethereum/common"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/config"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/evm"

	"math/big"

	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/mcp"
	assetmanager "github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/resources"

	"github.com/finiteloopme/goutils/pkg/log"
	oserr "github.com/finiteloopme/goutils/pkg/v2/os/err"
)

func main() {
	cfg, err := config.ParseFlags()
	oserr.PanicIfError("error parsing flags", err)

	server := mcp.NewServer()

	client := evm.NewClient(cfg.RPCEndpoint, cfg.Signer)

	rwaManager, err := assetmanager.NewRWAManager(
		client,
		common.HexToAddress(cfg.RWAContractAddress), // Use the parsed address
	)
	log.Infof("Successfully connected to the Asset Manager: %v", cfg.RWAContractAddress)

	// r, err := rwaManager.GetAllAssets(context.Background())
	// fmt.Println(r)
	server.RegisterTool(
		"list-assets",
		"Get all the on chain assets available and managed by the asset manager",
		func() (any, error) { return rwaManager.GetAllAssets(context.Background()) },
		map[string]string{},
	)

	server.RegisterTool(
		"buy-asset",
		"Buy a specific asset on chain using the contract address, stock id, and amount of tokens to use",
		func() (any, error) {
			stock, err := assetmanager.NewStockAsset(client, common.HexToAddress("0x663F3ad617193148711d28f5334eE4Ed07016602"))
			oserr.PanicIfError("error creating stock asset", err)
			assetId := big.NewInt(1) // Convert int to *big.Int
			// client.NewTransactionWithValue(400)
			tx, err := stock.Buy(assetId, 1)
			if oserr.IsError(err) {
				return fmt.Sprintf("error buying asset: %v", err), nil
			}
			// oserr.PanicIfError("error buying asset", err)
			return fmt.Sprintf("Transaction hash: %s", tx.Hash().Hex()), nil
			//return fmt.Sprintf("Buying asset is not implemented yet"), nil
		},
		map[string]string{"assetId": "Stock Asset ID", "amount": "Amount of tokens to use"},
	)

	server.RegisterTool(
		"sell-asset",
		"Sell a specific asset on chain using the contract address, stock id, and amount of tokens to use",
		func() (any, error) { return fmt.Sprintf("Buying asset is not implemented yet"), nil },
		map[string]string{},
	)

	server.Serve()
}
