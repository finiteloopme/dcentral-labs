package resources

import (
	"context"
	"fmt"
	"math/big"
	"strconv"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/generated/contract"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/evm"
	"github.com/finiteloopme/goutils/pkg/log"
	oserr "github.com/finiteloopme/goutils/pkg/v2/os/err"
	"github.com/mark3labs/mcp-go/mcp"
)

type StockEventListener struct {
	client *evm.Chain
}

func NewStockEventListener(client *evm.Chain) *StockEventListener {
	return &StockEventListener{
		client: client,
	}
}

func (e *StockEventListener) SubscribeToPurchase(contractAddress string, purchaseAmount int) {

	_stockContract, err := contract.NewStockAsset(common.HexToAddress(contractAddress), e.client.WsClient)
	oserr.WarnIfError("failed to instantiate a contract for StockAsset: %w", err)
	if err != nil {
		return
	}

	watchOpts := &bind.WatchOpts{Context: context.Background(), Start: nil}
	logs := make(chan *contract.StockAssetAssetIssued)
	go func() {
		subscription, err := _stockContract.WatchAssetIssued(watchOpts, logs, make([]*big.Int, 0), make([]common.Address, 0))
		oserr.PanicIfError("failed to subscribe to AssetIssued events: %w", err)
		defer subscription.Unsubscribe()
		for {
			select {
			case err := <-subscription.Err():
				log.Warn("error during subscription: %w", err)
				break
			case msg := <-logs:
				stock := NewStockAsset(e.client)
				stock.RefreshContract(contractAddress)
				txn, err := stock.Buy(msg.AssetId, int64(purchaseAmount))
				if err != nil {
					log.Warnf("failed to automatically buy asset %v after issue: %w", msg.AssetId, err)
					log.Warn("Unsubscribing...", err)
					break
				}
				log.Infof("Automatic purchase succeeded with transaction: %s", txn.Hash().Hex())
			}
		}
	}()
}

func (e *StockEventListener) SubscribeToPurchaseHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	assetContractAddress, err := request.RequireString("stockAssetContractAddress")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Need contract address for the stock. %v", err.Error())), nil
	}
	_purchaseAmount, err := request.RequireString("purchaseAmount")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Need purchase amount for the stock. %v", err.Error())), nil
	}
	purchaseAmount, err := strconv.Atoi(_purchaseAmount)
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Invalid purchase amount: %v", err.Error())), nil
	}
	e.SubscribeToPurchase(assetContractAddress, purchaseAmount)
	return mcp.NewToolResultText("Subscribed to purchase stocks automatically"), nil
}
