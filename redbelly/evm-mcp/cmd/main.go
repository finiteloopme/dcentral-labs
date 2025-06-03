package main

import (
	"context"

	"github.com/ethereum/go-ethereum/common"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/config"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/evm"

	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/mcp"
	assetmanager "github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/resources"

	"github.com/finiteloopme/goutils/pkg/log"
	oserr "github.com/finiteloopme/goutils/pkg/v2/os/err"
)

func main() {
	cfg, err := config.ParseFlags()
	oserr.PanicIfError("error parsing flags", err)

	done := make(chan struct{})
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
	)

	server.Serve()
	<-done
}
