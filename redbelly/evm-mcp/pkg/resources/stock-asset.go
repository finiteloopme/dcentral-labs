package resources

import (
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/generated/contract"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/evm"
)

type StockAsset struct {
	chain      *evm.Chain
	caller     *contract.StockAssetCaller     // Use the generated caller
	transactor *contract.StockAssetTransactor // Use the generated transactor
	address    common.Address
}

func NewStockAsset(chain *evm.Chain, contractAddress common.Address) (*StockAsset, error) {
	caller, err := contract.NewStockAssetCaller(contractAddress, chain.Client)
	if err != nil {
		return nil, fmt.Errorf("failed to instantiate StockAssetCaller: %w", err)
	}

	transactor, err := contract.NewStockAssetTransactor(contractAddress, chain.Client)
	if err != nil {
		return nil, fmt.Errorf("failed to instantiate StockAssetTransactor: %w", err)
	}

	return &StockAsset{
		chain:      chain,
		caller:     caller,
		transactor: transactor,
		address:    contractAddress,
	}, nil
}

// GetAllStocks retrieves all stock symbols and their details from the smart contract.
func (s *StockAsset) GetAllStocks() ([]*big.Int, error) {
	stocks, err := s.caller.GetAllAssetIds(&bind.CallOpts{})
	if err != nil {
		return nil, fmt.Errorf("failed to get all stocks: %w", err)
	}

	return stocks, nil
}

// BuyAsset allows a user to buy a specified amount of an asset.
func (s *StockAsset) Buy(assetId *big.Int, tokenAmount int64) (*types.Transaction, error) {

	tx, err := s.transactor.Buy(s.chain.NewTransactionWithValue(tokenAmount), assetId)
	if err != nil {
		return nil, fmt.Errorf("failed to buy asset %v: %w", assetId, err)
	}
	return tx, nil
}

// SellAsset allows a user to sell a specified amount of an asset.
func (s *StockAsset) Sell(assetId *big.Int) (*types.Transaction, error) {
	tx, err := s.transactor.Sell(s.chain.NewTransaction(), assetId)
	if err != nil {
		return nil, fmt.Errorf("failed to sell asset %v: %w", assetId, err)
	}
	return tx, nil
}
