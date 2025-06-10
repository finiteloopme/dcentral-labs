package resources

import (
	"context"
	"fmt"
	"math/big"
	"strconv"

	"github.com/ethereum/go-ethereum/accounts/abi/bind/v2"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/generated/contract"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/evm"
	"github.com/finiteloopme/goutils/pkg/log"
	"github.com/mark3labs/mcp-go/mcp"
)

type StockContract struct {
	chain      *evm.Chain
	caller     *contract.EquityCaller
	transactor *contract.EquityTransactor
	address    common.Address
}

func NewStockContract(chain *evm.Chain, _contractAddress string) *StockContract {
	contractAddress := common.HexToAddress(_contractAddress)
	caller, err := contract.NewEquityCaller(contractAddress, chain.Client)
	if err != nil {
		log.Warnf("failed to instantiate EquityCaller: %w", err)
	}
	transactor, err := contract.NewEquityTransactor(contractAddress, chain.Client)
	if err != nil {
		log.Warnf("failed to instantiate EquityTransactor: %w", err)
	}
	return &StockContract{
		chain:      chain,
		caller:     caller,
		transactor: transactor,
		address:    contractAddress,
	}
}

// func (s *StockContract) RefreshContract(_contractAddress string) error {
// 	contractAddress := common.HexToAddress(_contractAddress)
// 	caller, err := contract.NewEquityCaller(contractAddress, s.chain.Client)
// 	if err != nil {
// 		log.Warnf("failed to instantiate EquityCaller: %w", err)
// 		return fmt.Errorf("failed to instantiate EquityCaller: %w", err)
// 	}
// 	transactor, err := contract.NewEquityTransactor(contractAddress, s.chain.Client)
// 	if err != nil {
// 		log.Warnf("failed to instantiate EquityTransactor: %w", err)
// 		return fmt.Errorf("failed to instantiate EquityTransactor: %w", err)
// 	}
// 	s.caller = caller
// 	s.transactor = transactor
// 	s.address = contractAddress

// 	return nil
// }

func (s *StockContract) GetAllAssets(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	stocks, err := s.GetAllStocks()
	if err != nil {
		return nil, fmt.Errorf("failed to get all stocks: %w", err)
	}

	return mcp.NewToolResultText(fmt.Sprintf("%v", stocks)), nil
}

func (s *StockContract) GetAllStocks() ([]*contract.EquityContractV3Equity, error) {
	stockIds, err := s.caller.GetAllAssetIds(&bind.CallOpts{})
	if err != nil {
		return nil, fmt.Errorf("failed to get all stocks: %w", err)
	}

	return s.GetStocksByIds(stockIds)
}

func (s *StockContract) GetAssetsByIds(assetIds []*big.Int) ([]*contract.EquityContractV3Equity, error) {
	stocks, err := s.GetStocksByIds(assetIds)
	if err != nil {
		return nil, fmt.Errorf("failed to get stocks: %w", err)
	}
	return stocks, nil
}

func (s *StockContract) GetStocksByIds(assetIds []*big.Int) ([]*contract.EquityContractV3Equity, error) {
	var stocks []*contract.EquityContractV3Equity
	for _, assetId := range assetIds {
		stock, err := s.caller.GetEquityDetailsFromId(&bind.CallOpts{}, assetId)
		if err != nil {
			return nil, fmt.Errorf("failed to get stock details: %w", err)
		}
		stocks = append(stocks, &stock)
	}
	return stocks, nil
}

func (s *StockContract) GetMyAssets(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	stockIds, err := s.caller.GetUserAssetIds(&bind.CallOpts{}, *s.chain.Signer.Address)
	if err != nil {
		return nil, fmt.Errorf("failed to get stocks for user: %s. error: %w", *s.chain.Signer.Address, err)
	}
	if stocks, err := s.GetStocksByIds(stockIds); err != nil {
		return nil, fmt.Errorf("failed to get s.GetAssetsByIds(stockIds): %w", err)
	} else {
		return mcp.NewToolResultText(fmt.Sprintf("%v", stocks)), nil
	}
}

func (s *StockContract) Buy(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	assetId, err := request.RequireString("assetId")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Asset ID is required: %v", err.Error())), nil
	}
	tokenAmount, err := request.RequireString("tokenAmount")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Token Amount is required: %v", err.Error())), nil
	}
	_assetId, err := strconv.ParseInt(assetId, 10, 64)
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Invalid asset ID: %v", err.Error())), nil
	}
	_tokenAmount, err := strconv.ParseInt(tokenAmount, 10, 64)
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Invalid token amount: %v", err.Error())), nil
	}
	txnReceipt, err := s.BuyStock(big.NewInt(_assetId), _tokenAmount)
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Error buying stock: %v", err.Error())), nil
	}
	return mcp.NewToolResultText(fmt.Sprintf("Transaction receipt for purchased stock is: %v", txnReceipt)), nil
}

func (s *StockContract) BuyStock(assetId *big.Int, tokenAmount int64) (*types.Receipt, error) {
	tx, err := s.transactor.Buy(s.chain.NewTransactionWithValue(tokenAmount), assetId)
	if err != nil {
		return nil, fmt.Errorf("failed to buy stock %v: %w", assetId, err)
	}
	receipt, err := s.chain.Client.TransactionReceipt(context.Background(), tx.Hash())
	if err != nil {
		return nil, fmt.Errorf("failed to get buy transaction receipt: %w", err)
	}
	if receipt.Status != types.ReceiptStatusSuccessful {
		return nil, fmt.Errorf("buy transaction failed: %w", err)
	}

	return receipt, nil
}

func (s *StockContract) Sell(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	assetId, err := request.RequireString("assetId")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Asset ID is required: %v", err.Error())), nil
	}
	_assetId, err := strconv.ParseInt(assetId, 10, 64)
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Invalid asset ID: %v", err.Error())), nil
	}
	txnReceipt, err := s.SellStock(big.NewInt(_assetId))
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Error selling asset: %v", err.Error())), nil
	}
	return mcp.NewToolResultText(fmt.Sprintf("Transaction receipt for the sold stock is: %v", txnReceipt)), nil

}

func (s StockContract) SellStock(assetId *big.Int) (*types.Receipt, error) {
	tx, err := s.transactor.Sell(s.chain.NewTransaction(), assetId)
	if err != nil {
		return nil, fmt.Errorf("failed to sell stock %v: %w", assetId, err)
	}
	receipt, err := s.chain.Client.TransactionReceipt(context.Background(), tx.Hash())
	if err != nil {
		return nil, fmt.Errorf("failed to get sell transaction receipt: %w", err)
	}
	if receipt.Status != types.ReceiptStatusSuccessful {
		return nil, fmt.Errorf("sell transaction failed: %w", err)
	}

	return receipt, nil
}
