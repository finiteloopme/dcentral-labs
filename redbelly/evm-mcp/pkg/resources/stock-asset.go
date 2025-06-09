package resources

import (
	"context"
	"encoding/json"
	"fmt"
	"math/big"
	"strconv"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/generated/contract"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/evm"
	"github.com/finiteloopme/goutils/pkg/log"
	oserr "github.com/finiteloopme/goutils/pkg/v2/os/err"
	"github.com/mark3labs/mcp-go/mcp"
)

type StockAsset struct {
	chain      *evm.Chain
	caller     *contract.StockAssetCaller     // Use the generated caller
	transactor *contract.StockAssetTransactor // Use the generated transactor
	address    common.Address
}

func (s *StockAsset) RefreshContract(address string) {
	contractAddress := common.HexToAddress(address)
	caller, err := contract.NewStockAssetCaller(contractAddress, s.chain.Client)
	oserr.PanicIfError("failed to instantiate StockAssetCaller: %w", err)
	transactor, err := contract.NewStockAssetTransactor(contractAddress, s.chain.Client)
	oserr.PanicIfError("failed to instantiate StockAssetTransactor: %w", err)
	s.caller = caller
	s.transactor = transactor
	s.address = contractAddress
}

func NewStockAsset(chain *evm.Chain) *StockAsset {
	return &StockAsset{
		chain: chain,
	}
}

// GetAllStocks retrieves all stock symbols and their details from the smart contract.
func (s *StockAsset) GetAllStocks() ([]*big.Int, error) {
	stocks, err := s.caller.GetAllAssetIds(&bind.CallOpts{})
	if err != nil {
		return nil, fmt.Errorf("failed to get all stocks: %w", err)
	}

	return stocks, nil
}

func (s *StockAsset) RetrieveMyStocks(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	userAddress := s.chain.Signer.Address.String()
	// userAddress, err := request.RequireString("userAddress")
	// if err != nil {
	// 	return mcp.NewToolResultText(fmt.Sprintf("User address is required: %v", err.Error())), nil
	// }
	assetContractAddress, err := request.RequireString("stockAssetContractAddress")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Need contract address for the stock. %v", err.Error())), nil
	}
	s.RefreshContract(assetContractAddress)
	allAssets, err := s.GetAllStocks()
	if err != nil {
		log.Warn("failed to get all assets", err)
		return mcp.NewToolResultText(fmt.Sprintf("failed to get all assets: %v", err.Error())), nil
	}
	type Asset struct {
		ID      *big.Int `json:"assetId"`
		Name    string   `json:"assetName"`
		Symbol  string   `json:"assetSymbol"`
		Balance *big.Int `json:"amountOwnedByUser"`
	}
	var assets []*Asset
	for _, asset := range allAssets {
		_asset, err := s.caller.AssetName(&bind.CallOpts{}, asset)
		if err != nil {
			return mcp.NewToolResultText(fmt.Sprintf("failed to get asset name: %v", err.Error())), nil
		}
		_balance, err := s.caller.BalanceOf(&bind.CallOpts{}, common.HexToAddress(userAddress), asset)
		if err != nil {
			return mcp.NewToolResultText(fmt.Sprintf("failed to retrieve balance of the asset: %v", err.Error())), nil
		}
		assets = append(assets, &Asset{
			ID:      asset,
			Name:    _asset,
			Balance: _balance,
		})
	}
	assetsInBytes, err := json.Marshal(assets)
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("failed to marshal assets: %v", err.Error())), nil
	}
	return mcp.NewToolResultText(string(assetsInBytes)), nil
}

// BuyAsset allows a user to buy a specified amount of an asset.
func (s *StockAsset) Buy(assetId *big.Int, tokenAmount int64) (*types.Transaction, error) {

	tx, err := s.transactor.Buy(s.chain.NewTransactionWithValue(tokenAmount), assetId)
	if err != nil {
		return nil, fmt.Errorf("failed to buy asset %v: %w", assetId, err)
	}
	return tx, nil
}

func (s *StockAsset) BuyStock(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	assetId, err := request.RequireString("assetId")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Asset ID is required: %v", err.Error())), nil
	}
	tokenAmount, err := request.RequireString("tokenAmount")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Token Amount is required: %v", err.Error())), nil
	}
	assetContractAddress, err := request.RequireString("stockAssetContractAddress")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Need contract address for the stock. %v", err.Error())), nil
	}
	s.RefreshContract(assetContractAddress)
	_assetId, err := strconv.ParseInt(assetId, 10, 64)
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Invalid asset ID: %v", err.Error())), nil
	}
	_tokenAmount, err := strconv.ParseInt(tokenAmount, 10, 64)
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Invalid token amount: %v", err.Error())), nil
	}
	tx, err := s.Buy(big.NewInt(_assetId), _tokenAmount)
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Error buying asset: %v", err.Error())), nil
	}
	return mcp.NewToolResultText(fmt.Sprintf("Transaction hash: %s", tx.Hash().Hex())), nil
}

// SellAsset allows a user to sell a specified amount of an asset.
func (s *StockAsset) Sell(assetId *big.Int) (*types.Transaction, error) {
	tx, err := s.transactor.Sell(s.chain.NewTransaction(), assetId)
	if err != nil {
		return nil, fmt.Errorf("failed to sell asset %v: %w", assetId, err)
	}
	return tx, nil
}
