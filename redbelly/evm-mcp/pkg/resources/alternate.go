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
	oserr "github.com/finiteloopme/goutils/pkg/v2/os/err"
	"github.com/mark3labs/mcp-go/mcp"
)

type AlternateContract struct {
	chain *evm.Chain
	// signer     *evm.Signer
	caller     *contract.AlternateCaller
	transactor *contract.AlternateTransactor
	address    common.Address
}

type AlternateEntity struct {
	contract.AlternateAssetsV1AlternateAsset
	Id          big.Int `json:"assetId"`
	Category    string  `json:"category"`
	Description string  `json:"description"`
}

func NewAlternateContract(chain *evm.Chain, _contractAddress string) *AlternateContract {
	contractAddress := common.HexToAddress(_contractAddress)
	caller, err := contract.NewAlternateCaller(contractAddress, chain.Client)
	if err != nil {
		log.Warnf("failed to instantiate AlternateCaller: %w", err)
	}
	transactor, err := contract.NewAlternateTransactor(contractAddress, chain.Client)
	if err != nil {
		log.Warnf("failed to instantiate AlternateTransactor: %w", err)
	}
	return &AlternateContract{
		chain:  chain,
		caller: caller,
		// signer:     signer,
		transactor: transactor,
		address:    contractAddress,
	}
}

// func (s *AlternateContract) RefreshContract(_contractAddress string) error {
// 	contractAddress := common.HexToAddress(_contractAddress)
// 	caller, err := contract.NewAlternateCaller(contractAddress, s.chain.Client)
// 	if err != nil {
// 		log.Warnf("failed to instantiate AlternateCaller: %w", err)
// 		return fmt.Errorf("failed to instantiate AlternateCaller: %w", err)
// 	}
// 	transactor, err := contract.NewAlternateTransactor(contractAddress, s.chain.Client)
// 	if err != nil {
// 		log.Warnf("failed to instantiate AlternateTransactor: %w", err)
// 		return fmt.Errorf("failed to instantiate AlternateTransactor: %w", err)
// 	}
// 	s.caller = caller
// 	s.transactor = transactor
// 	s.address = contractAddress

// 	return nil
// }

func (s *AlternateContract) GetAllAssets(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	alternateAssets, err := s.GetAllAlternateAssets()
	if err != nil {
		return nil, fmt.Errorf("error GetAllAssets: : %w", err)
	}

	return mcp.NewToolResultText(fmt.Sprintf("%v", alternateAssets)), nil
}

func (s *AlternateContract) GetAllAlternateAssets() ([]AlternateEntity, error) {
	alternateAssetIds, err := s.caller.GetAllAssetIds(&bind.CallOpts{})
	if err != nil {
		return nil, fmt.Errorf("failed to get all AlternateAssets using address: %s. error: %w", s.address.Hex(), err)
	}

	return s.GetAlternateAssetsByIds(alternateAssetIds)
}

func (s *AlternateContract) GetAssetsByIds(assetIds []*big.Int) ([]AlternateEntity, error) {
	alternateAssets, err := s.GetAlternateAssetsByIds(assetIds)
	if err != nil {
		return nil, fmt.Errorf("failed to get AlternateAssets: %w", err)
	}
	return alternateAssets, nil
}

func (s *AlternateContract) GetAlternateAssetsByIds(assetIds []*big.Int) ([]AlternateEntity, error) {
	var alternateAssets []AlternateEntity
	for _, assetId := range assetIds {
		alternateAsset, err := s.caller.GetaltAssetsDetailsFromId(&bind.CallOpts{}, assetId)
		if err != nil {
			return nil, fmt.Errorf("failed to get AlternateAsset details: %w", err)
		}
		_alternateAsset := AlternateEntity{
			Id:                              *assetId,
			Category:                        AssetTypeAlternate.String(),
			AlternateAssetsV1AlternateAsset: alternateAsset,
			Description:                     fmt.Sprintf("%v asset is of type (category) %v with an assetId of %v", alternateAsset.Name, AssetTypeAlternate.String(), assetId.String()),
		}
		alternateAssets = append(alternateAssets, _alternateAsset)
	}
	return alternateAssets, nil
}

func (s *AlternateContract) GetMyAssets(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	signerPrivKey, err := request.RequireString("signer")
	if err != nil {
		return mcp.NewToolResultText("User profile hasn't been set properly to retrieve AlternateAssets.  Requires signer key to be set"), nil
	}
	signer := evm.NewSigner(signerPrivKey)

	log.Infof("Getting AlternateAssets for user: %v", signer.Address.Hex())
	alternateAssetIds, err := s.caller.GetUserAssetIds(&bind.CallOpts{}, *signer.Address)
	if err != nil {
		return nil, fmt.Errorf("failed to get AlternateAssets for user: %s. error: %w", *signer.Address, err)
	}
	if alternateAssets, err := s.GetAlternateAssetsByIds(alternateAssetIds); err != nil {
		return nil, fmt.Errorf("failed to get s.GetAssetsByIds(alternateAssetIds): %w", err)
	} else {
		return mcp.NewToolResultText(fmt.Sprintf("%v", alternateAssets)), nil
	}
}

func (s *AlternateContract) Buy(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	signerPrivKey, err := request.RequireString("signer")
	if err != nil {
		return mcp.NewToolResultText("User profile hasn't been set properly to buy alternateAssets.  Requires signer key to be set"), nil
	}
	signer := evm.NewSigner(signerPrivKey)
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
	txnReceipt, err := s.BuyAlternateAsset(big.NewInt(_assetId), _tokenAmount, signer)
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Error buying AlternateAsset: %v", err.Error())), nil
	}
	return mcp.NewToolResultText(fmt.Sprintf("Transaction order submitted for purchasing AlternateAsset: %v", txnReceipt.Hash().Hex())), nil
}

func (s *AlternateContract) BuyAlternateAsset(assetId *big.Int, tokenAmount int64, signer *evm.Signer) (*types.Transaction, error) {
	tx, err := s.transactor.Buy(s.chain.NewTransactionWithValue(tokenAmount, signer), assetId)
	if err != nil {
		log.Warnf("failed to buy AlternateAsset %v: %w", assetId, err)
		return nil, fmt.Errorf("failed to buy AlternateAsset %v: %w", assetId, err)
	}
	return tx, nil
}

func (s *AlternateContract) Sell(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	signerPrivKey, err := request.RequireString("signer")
	if err != nil {
		return mcp.NewToolResultText("User profile hasn't been set properly to sell alternateAssets.  Requires signer key to be set"), nil
	}
	signer := evm.NewSigner(signerPrivKey)
	assetId, err := request.RequireString("assetId")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Asset ID is required: %v", err.Error())), nil
	}
	_assetId, err := strconv.ParseInt(assetId, 10, 64)
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Invalid asset ID: %v", err.Error())), nil
	}
	txnReceipt, err := s.SellAlternateAsset(big.NewInt(_assetId), signer)
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Error selling asset: %v", err.Error())), nil
	}
	return mcp.NewToolResultText(fmt.Sprintf("Transaction submitted for sell order of the AlternateAsset is: %v", txnReceipt.Hash().Hex())), nil

}

func (s *AlternateContract) SellAlternateAsset(assetId *big.Int, signer *evm.Signer) (*types.Transaction, error) {
	tx, err := s.transactor.Sell(s.chain.NewTransaction(signer), assetId)
	if err != nil {
		return nil, fmt.Errorf("failed to sell AlternateAsset %v: %w", assetId, err)
	}

	return tx, nil
}

func (e *AlternateContract) SubscribeToPurchase(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	signerPrivKey, err := request.RequireString("signer")
	if err != nil {
		return mcp.NewToolResultText("User profile hasn't been set properly to automatically purchase alternateAssets.  Requires signer key to be set"), nil
	}
	signer := evm.NewSigner(signerPrivKey)
	// assetContractAddress, err := request.RequireString("AlternateAssetAssetContractAddress")
	// if err != nil {
	// 	return mcp.NewToolResultText(fmt.Sprintf("Need contract address for the AlternateAsset. %v", err.Error())), nil
	// }
	_purchaseAmount, err := request.RequireString("purchaseAmount")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Need purchase amount for the AlternateAsset. %v", err.Error())), nil
	}
	purchaseAmount, err := strconv.Atoi(_purchaseAmount)
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Invalid purchase amount: %v", err.Error())), nil
	}
	e.SubscribeToAlternateAssets(purchaseAmount, signer)
	return mcp.NewToolResultText("Subscribed to purchase alternateAssets automatically"), nil
}

func (s *AlternateContract) SubscribeToAlternateAssets(purchaseAmount int, signer *evm.Signer) {
	_alternateContract, err := contract.NewAlternate(s.address, s.chain.WsClient)
	oserr.WarnIfError("failed to instantiate a contract for AlternateAsset: %w", err)
	if err != nil {
		return
	}

	watchOpts := &bind.WatchOpts{Context: context.Background(), Start: nil}
	logs := make(chan *contract.AlternateAssetSold, 0)
	go func() {
		subscription, err := _alternateContract.WatchAssetSold(watchOpts, logs, make([]*big.Int, 0), make([]common.Address, 0))
		oserr.PanicIfError("failed to subscribe to AlternateAssetSold events: %w", err)
		defer subscription.Unsubscribe()
		for {
			select {
			case err := <-subscription.Err():
				log.Warn("error during subscription: %w", err)
				break
			case msg := <-logs:
				// AlternateAsset := NewAlternateAssetAsset(e.client)
				// AlternateAsset.RefreshContract(contractAddress)
				txn, err := s.BuyAlternateAsset(msg.AssetId, int64(purchaseAmount), signer)
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
