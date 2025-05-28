package main

import (
	"context"
	"fmt"

	"github.com/ethereum/go-ethereum/common"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/config"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/evm"

	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/mcp"
	assetmanager "github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/resources"

	// mcp "github.com/metoro-io/mcp-golang"
	// "github.com/metoro-io/mcp-golang/transport/stdio"

	oserr "github.com/finiteloopme/goutils/pkg/v2/os/err"
)

func main() {
	cfg, err := config.ParseFlags()
	oserr.PanicIfError("error parsing flags", err)

	done := make(chan struct{})
	server := mcp.NewServer()
	// server := mcp.NewServer(stdio.NewStdioServerTransport())

	client := evm.NewClient(cfg.RPCEndpoint)
	// Use a default ABI path or make it configurable as well if needed
	abiPath := "/Users/kunall/scratchpad/dcentral-labs/redbelly/portfolio-manager/abi/RWA_Manager.json"

	rwaManager, err := assetmanager.NewRWAManager(client,
		// cfg.OwnerAddress,
		common.HexToAddress(cfg.RWAContractAddress), // Use the parsed address
		abiPath)
	fmt.Println("Successfully connected to an EVM chain!")

	r, err := rwaManager.GetAllAssets(context.Background())
	fmt.Println(r)
	server.RegisterTool(
		"list-assets",
		"Get all the on chain assets available and managed by the asset manager",
		func() (any, error) { return rwaManager.GetAllAssets(context.Background()) },
	)
	// err = server.RegisterTool(
	// 	"list-assets",
	// 	"Get all the on chain assets available and managed by the asset manager",
	// 	// func(args *HelloArguments) (*mcp.ToolResponse, error) {
	// 	func(args *evm.SignerAddress) (*mcp.ToolResponse, error) {
	// 		response, _ := rwaManager.GetAllAssets(context.Background())
	// 		return mcp.NewToolResponse(
	// 			mcp.NewTextContent(fmt.Sprintf("%v", response)),
	// 		), nil
	// 	})
	// oserr.PanicIfError(fmt.Sprintf("error registering tool: %v", "list-assets"), err)

	server.Serve()
	<-done
}
