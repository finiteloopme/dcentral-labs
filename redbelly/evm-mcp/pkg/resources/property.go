package resources

// import (
// 	"context"
// 	"fmt"
// 	"math/big"
// 	"strconv"

// 	"github.com/ethereum/go-ethereum/accounts/abi/bind/v2"
// 	"github.com/ethereum/go-ethereum/common"
// 	"github.com/ethereum/go-ethereum/core/types"
// 	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/generated/contract"
// 	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/evm"
// 	"github.com/finiteloopme/goutils/pkg/log"
// 	oserr "github.com/finiteloopme/goutils/pkg/v2/os/err"
// 	"github.com/mark3labs/mcp-go/mcp"
// )

// type PropertyContract struct {
// 	chain *evm.Chain
// 	// signer     *evm.Signer
// 	caller     *contract.EquityCaller
// 	transactor *contract.EquityTransactor
// 	address    common.Address
// }

// type StockEntity struct {
// 	contract.EquityContractV3Equity
// 	Id          big.Int `json:"assetId"`
// 	Category    string  `json:"category"`
// 	Description string  `json:"description"`
// }

// func NewPropertyContract(chain *evm.Chain, _contractAddress string) *PropertyContract {
// 	contractAddress := common.HexToAddress(_contractAddress)
// 	caller, err := contract.NewEquityCaller(contractAddress, chain.Client)
// 	if err != nil {
// 		log.Warnf("failed to instantiate EquityCaller: %w", err)
// 	}
// 	transactor, err := contract.NewEquityTransactor(contractAddress, chain.Client)
// 	if err != nil {
// 		log.Warnf("failed to instantiate EquityTransactor: %w", err)
// 	}
// 	return &PropertyContract{
// 		chain:  chain,
// 		caller: caller,
// 		// signer:     signer,
// 		transactor: transactor,
// 		address:    contractAddress,
// 	}
// }

// // func (s *PropertyContract) RefreshContract(_contractAddress string) error {
// // 	contractAddress := common.HexToAddress(_contractAddress)
// // 	caller, err := contract.NewEquityCaller(contractAddress, s.chain.Client)
// // 	if err != nil {
// // 		log.Warnf("failed to instantiate EquityCaller: %w", err)
// // 		return fmt.Errorf("failed to instantiate EquityCaller: %w", err)
// // 	}
// // 	transactor, err := contract.NewEquityTransactor(contractAddress, s.chain.Client)
// // 	if err != nil {
// // 		log.Warnf("failed to instantiate EquityTransactor: %w", err)
// // 		return fmt.Errorf("failed to instantiate EquityTransactor: %w", err)
// // 	}
// // 	s.caller = caller
// // 	s.transactor = transactor
// // 	s.address = contractAddress

// // 	return nil
// // }

// func (s *PropertyContract) GetAllAssets(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
// 	stocks, err := s.GetAllStocks()
// 	if err != nil {
// 		return nil, fmt.Errorf("error GetAllAssets: : %w", err)
// 	}

// 	return mcp.NewToolResultText(fmt.Sprintf("%v", stocks)), nil
// }

// func (s *PropertyContract) GetAllStocks() ([]StockEntity, error) {
// 	stockIds, err := s.caller.GetAllAssetIds(&bind.CallOpts{})
// 	if err != nil {
// 		return nil, fmt.Errorf("failed to get all stocks using address: %s. error: %w", s.address.Hex(), err)
// 	}

// 	return s.GetStocksByIds(stockIds)
// }

// func (s *PropertyContract) GetAssetsByIds(assetIds []*big.Int) ([]StockEntity, error) {
// 	stocks, err := s.GetStocksByIds(assetIds)
// 	if err != nil {
// 		return nil, fmt.Errorf("failed to get stocks: %w", err)
// 	}
// 	return stocks, nil
// }

// func (s *PropertyContract) GetStocksByIds(assetIds []*big.Int) ([]StockEntity, error) {
// 	var stocks []StockEntity
// 	for _, assetId := range assetIds {
// 		stock, err := s.caller.GetEquityDetailsFromId(&bind.CallOpts{}, assetId)
// 		if err != nil {
// 			return nil, fmt.Errorf("failed to get stock details: %w", err)
// 		}
// 		equity := StockEntity{
// 			Id:                     *assetId,
// 			Category:               AssetTypeStock.String(),
// 			EquityContractV3Equity: stock,
// 			Description:            fmt.Sprintf("%v asset is of type (category) %v with an assetId of %v", stock.Name, AssetTypeStock.String(), assetId.String()),
// 		}
// 		stocks = append(stocks, equity)
// 	}
// 	return stocks, nil
// }

// func (s *PropertyContract) GetMyAssets(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
// 	signerPrivKey, err := request.RequireString("signer")
// 	if err != nil {
// 		return mcp.NewToolResultText("User profile hasn't been set properly to retrieve stocks.  Requires signer key to be set"), nil
// 	}
// 	signer := evm.NewSigner(signerPrivKey)

// 	log.Infof("Getting stocks for user: %v", signer.Address.Hex())
// 	stockIds, err := s.caller.GetUserAssetIds(&bind.CallOpts{}, *signer.Address)
// 	if err != nil {
// 		return nil, fmt.Errorf("failed to get stocks for user: %s. error: %w", *signer.Address, err)
// 	}
// 	if stocks, err := s.GetStocksByIds(stockIds); err != nil {
// 		return nil, fmt.Errorf("failed to get s.GetAssetsByIds(stockIds): %w", err)
// 	} else {
// 		return mcp.NewToolResultText(fmt.Sprintf("%v", stocks)), nil
// 	}
// }

// func (s *PropertyContract) Buy(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
// 	signerPrivKey, err := request.RequireString("signer")
// 	if err != nil {
// 		return mcp.NewToolResultText("User profile hasn't been set properly to buy stocks.  Requires signer key to be set"), nil
// 	}
// 	signer := evm.NewSigner(signerPrivKey)
// 	assetId, err := request.RequireString("assetId")
// 	if err != nil {
// 		return mcp.NewToolResultText(fmt.Sprintf("Asset ID is required: %v", err.Error())), nil
// 	}
// 	tokenAmount, err := request.RequireString("tokenAmount")
// 	if err != nil {
// 		return mcp.NewToolResultText(fmt.Sprintf("Token Amount is required: %v", err.Error())), nil
// 	}
// 	_assetId, err := strconv.ParseInt(assetId, 10, 64)
// 	if err != nil {
// 		return mcp.NewToolResultText(fmt.Sprintf("Invalid asset ID: %v", err.Error())), nil
// 	}
// 	_tokenAmount, err := strconv.ParseInt(tokenAmount, 10, 64)
// 	if err != nil {
// 		return mcp.NewToolResultText(fmt.Sprintf("Invalid token amount: %v", err.Error())), nil
// 	}
// 	txnReceipt, err := s.BuyStock(big.NewInt(_assetId), _tokenAmount, signer)
// 	if err != nil {
// 		return mcp.NewToolResultText(fmt.Sprintf("Error buying stock: %v", err.Error())), nil
// 	}
// 	return mcp.NewToolResultText(fmt.Sprintf("Transaction order submitted for purchasing stock: %v", txnReceipt.Hash().Hex())), nil
// }

// func (s *PropertyContract) BuyStock(assetId *big.Int, tokenAmount int64, signer *evm.Signer) (*types.Transaction, error) {
// 	tx, err := s.transactor.Buy(s.chain.NewTransactionWithValue(tokenAmount, signer), assetId)
// 	if err != nil {
// 		log.Warnf("failed to buy stock %v: %w", assetId, err)
// 		return nil, fmt.Errorf("failed to buy stock %v: %w", assetId, err)
// 	}
// 	return tx, nil
// }

// func (s *PropertyContract) Sell(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
// 	signerPrivKey, err := request.RequireString("signer")
// 	if err != nil {
// 		return mcp.NewToolResultText("User profile hasn't been set properly to sell stocks.  Requires signer key to be set"), nil
// 	}
// 	signer := evm.NewSigner(signerPrivKey)
// 	assetId, err := request.RequireString("assetId")
// 	if err != nil {
// 		return mcp.NewToolResultText(fmt.Sprintf("Asset ID is required: %v", err.Error())), nil
// 	}
// 	_assetId, err := strconv.ParseInt(assetId, 10, 64)
// 	if err != nil {
// 		return mcp.NewToolResultText(fmt.Sprintf("Invalid asset ID: %v", err.Error())), nil
// 	}
// 	txnReceipt, err := s.SellStock(big.NewInt(_assetId), signer)
// 	if err != nil {
// 		return mcp.NewToolResultText(fmt.Sprintf("Error selling asset: %v", err.Error())), nil
// 	}
// 	return mcp.NewToolResultText(fmt.Sprintf("Transaction submitted for sell order of the stock is: %v", txnReceipt.Hash().Hex())), nil

// }

// func (s *PropertyContract) SellStock(assetId *big.Int, signer *evm.Signer) (*types.Transaction, error) {
// 	tx, err := s.transactor.Sell(s.chain.NewTransaction(signer), assetId)
// 	if err != nil {
// 		return nil, fmt.Errorf("failed to sell stock %v: %w", assetId, err)
// 	}

// 	return tx, nil
// }

// func (e *PropertyContract) SubscribeToPurchase(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
// 	signerPrivKey, err := request.RequireString("signer")
// 	if err != nil {
// 		return mcp.NewToolResultText("User profile hasn't been set properly to automatically purchase stocks.  Requires signer key to be set"), nil
// 	}
// 	signer := evm.NewSigner(signerPrivKey)
// 	// assetContractAddress, err := request.RequireString("stockAssetContractAddress")
// 	// if err != nil {
// 	// 	return mcp.NewToolResultText(fmt.Sprintf("Need contract address for the stock. %v", err.Error())), nil
// 	// }
// 	_purchaseAmount, err := request.RequireString("purchaseAmount")
// 	if err != nil {
// 		return mcp.NewToolResultText(fmt.Sprintf("Need purchase amount for the stock. %v", err.Error())), nil
// 	}
// 	purchaseAmount, err := strconv.Atoi(_purchaseAmount)
// 	if err != nil {
// 		return mcp.NewToolResultText(fmt.Sprintf("Invalid purchase amount: %v", err.Error())), nil
// 	}
// 	e.SubscribeToStocks(purchaseAmount, signer)
// 	return mcp.NewToolResultText("Subscribed to purchase stocks automatically"), nil
// }

// func (s *PropertyContract) SubscribeToStocks(purchaseAmount int, signer *evm.Signer) {
// 	_PropertyContract, err := contract.NewEquity(s.address, s.chain.WsClient)
// 	oserr.WarnIfError("failed to instantiate a contract for StockAsset: %w", err)
// 	if err != nil {
// 		return
// 	}

// 	watchOpts := &bind.WatchOpts{Context: context.Background(), Start: nil}
// 	logs := make(chan *contract.EquityAssetSold, 0)
// 	go func() {
// 		subscription, err := _PropertyContract.WatchAssetSold(watchOpts, logs, make([]*big.Int, 0), make([]common.Address, 0))
// 		oserr.PanicIfError("failed to subscribe to StockAssetSold events: %w", err)
// 		defer subscription.Unsubscribe()
// 		for {
// 			select {
// 			case err := <-subscription.Err():
// 				log.Warn("error during subscription: %w", err)
// 				break
// 			case msg := <-logs:
// 				// stock := NewStockAsset(e.client)
// 				// stock.RefreshContract(contractAddress)
// 				txn, err := s.BuyStock(msg.AssetId, int64(purchaseAmount), signer)
// 				if err != nil {
// 					log.Warnf("failed to automatically buy asset %v after issue: %w", msg.AssetId, err)
// 					log.Warn("Unsubscribing...", err)
// 					break
// 				}
// 				log.Infof("Automatic purchase succeeded with transaction: %s", txn.Hash().Hex())
// 			}
// 		}
// 	}()
// }
