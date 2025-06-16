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

type PropertyContract struct {
	chain *evm.Chain
	// signer     *evm.Signer
	caller     *contract.PropertyCaller
	transactor *contract.PropertyTransactor
	address    common.Address
}

type PropertyEntity struct {
	contract.AddPropertyInArrayOtherDetails
	Id          big.Int `json:"assetId"`
	Category    string  `json:"category"`
	Description string  `json:"description"`
}

func NewPropertyContract(chain *evm.Chain, _contractAddress string) *PropertyContract {
	contractAddress := common.HexToAddress(_contractAddress)
	caller, err := contract.NewPropertyCaller(contractAddress, chain.Client)
	if err != nil {
		log.Warnf("failed to instantiate PropertyCaller: %w", err)
	}
	transactor, err := contract.NewPropertyTransactor(contractAddress, chain.Client)
	if err != nil {
		log.Warnf("failed to instantiate PropertyTransactor: %w", err)
	}
	return &PropertyContract{
		chain:  chain,
		caller: caller,
		// signer:     signer,
		transactor: transactor,
		address:    contractAddress,
	}
}

// func (s *PropertyContract) RefreshContract(_contractAddress string) error {
// 	contractAddress := common.HexToAddress(_contractAddress)
// 	caller, err := contract.NewPropertyCaller(contractAddress, s.chain.Client)
// 	if err != nil {
// 		log.Warnf("failed to instantiate PropertyCaller: %w", err)
// 		return fmt.Errorf("failed to instantiate PropertyCaller: %w", err)
// 	}
// 	transactor, err := contract.NewPropertyTransactor(contractAddress, s.chain.Client)
// 	if err != nil {
// 		log.Warnf("failed to instantiate PropertyTransactor: %w", err)
// 		return fmt.Errorf("failed to instantiate PropertyTransactor: %w", err)
// 	}
// 	s.caller = caller
// 	s.transactor = transactor
// 	s.address = contractAddress

// 	return nil
// }

func (s *PropertyContract) GetAllAssets(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	perperties, err := s.GetAllProperties()
	if err != nil {
		return nil, fmt.Errorf("error GetAllAssets: : %w", err)
	}

	return mcp.NewToolResultText(fmt.Sprintf("%v", perperties)), nil
}

func (s *PropertyContract) GetAllProperties() ([]PropertyEntity, error) {
	propertyIds, err := s.caller.GetAllAssetIds(&bind.CallOpts{})
	if err != nil {
		return nil, fmt.Errorf("failed to get all properties using address: %s. error: %w", s.address.Hex(), err)
	}

	return s.GetPropertiesByIds(propertyIds)
}

func (s *PropertyContract) GetAssetsByIds(assetIds []*big.Int) ([]PropertyEntity, error) {
	properties, err := s.GetPropertiesByIds(assetIds)
	if err != nil {
		return nil, fmt.Errorf("failed to get properties: %w", err)
	}
	return properties, nil
}

func (s *PropertyContract) GetPropertiesByIds(assetIds []*big.Int) ([]PropertyEntity, error) {
	var properties []PropertyEntity
	for _, assetId := range assetIds {
		property, err := s.caller.AllPropertiesDetails(&bind.CallOpts{}, assetId)
		if err != nil {
			return nil, fmt.Errorf("failed to get property details: %w", err)
		}
		_property := PropertyEntity{
			Id:                             *assetId,
			Category:                       AssetTypeProperty.String(),
			AddPropertyInArrayOtherDetails: property,
			Description:                    fmt.Sprintf("%v asset is of type (category) %v with an assetId of %v", property.Description, AssetTypeProperty.String(), assetId.String()),
		}
		properties = append(properties, _property)
	}
	return properties, nil
}

func (s *PropertyContract) GetMyAssets(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	signerPrivKey, err := request.RequireString("signer")
	if err != nil {
		return mcp.NewToolResultText("User profile hasn't been set properly to retrieve properties.  Requires signer key to be set"), nil
	}
	signer := evm.NewSigner(signerPrivKey)

	log.Infof("Getting properties for user: %v", signer.Address.Hex())
	propertyIds, err := s.caller.GetUserAssetIds(&bind.CallOpts{}, *signer.Address)
	if err != nil {
		return nil, fmt.Errorf("failed to get properties for user: %s. error: %w", *signer.Address, err)
	}
	if properties, err := s.GetPropertiesByIds(propertyIds); err != nil {
		return nil, fmt.Errorf("failed to get s.GetAssetsByIds(propertyIds): %w", err)
	} else {
		return mcp.NewToolResultText(fmt.Sprintf("%v", properties)), nil
	}
}

func (s *PropertyContract) Buy(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	signerPrivKey, err := request.RequireString("signer")
	if err != nil {
		return mcp.NewToolResultText("User profile hasn't been set properly to buy properties.  Requires signer key to be set"), nil
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
	txnReceipt, err := s.BuyProperty(big.NewInt(_assetId), _tokenAmount, signer)
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Error buying property: %v", err.Error())), nil
	}
	return mcp.NewToolResultText(fmt.Sprintf("Transaction order submitted for purchasing property: %v", txnReceipt.Hash().Hex())), nil
}

func (s *PropertyContract) BuyProperty(assetId *big.Int, tokenAmount int64, signer *evm.Signer) (*types.Transaction, error) {
	tx, err := s.transactor.Buy(s.chain.NewTransactionWithValue(tokenAmount, signer), assetId)
	if err != nil {
		log.Warnf("failed to buy property %v: %w", assetId, err)
		return nil, fmt.Errorf("failed to buy property %v: %w", assetId, err)
	}
	return tx, nil
}

func (s *PropertyContract) Sell(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	signerPrivKey, err := request.RequireString("signer")
	if err != nil {
		return mcp.NewToolResultText("User profile hasn't been set properly to sell properties.  Requires signer key to be set"), nil
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
	txnReceipt, err := s.SellProperty(big.NewInt(_assetId), signer)
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Error selling asset: %v", err.Error())), nil
	}
	return mcp.NewToolResultText(fmt.Sprintf("Transaction submitted for sell order of the property is: %v", txnReceipt.Hash().Hex())), nil

}

func (s *PropertyContract) SellProperty(assetId *big.Int, signer *evm.Signer) (*types.Transaction, error) {
	tx, err := s.transactor.Sell(s.chain.NewTransaction(signer), assetId)
	if err != nil {
		return nil, fmt.Errorf("failed to sell property %v: %w", assetId, err)
	}

	return tx, nil
}

func (e *PropertyContract) SubscribeToPurchase(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	signerPrivKey, err := request.RequireString("signer")
	if err != nil {
		return mcp.NewToolResultText("User profile hasn't been set properly to automatically purchase properties.  Requires signer key to be set"), nil
	}
	signer := evm.NewSigner(signerPrivKey)
	// assetContractAddress, err := request.RequireString("propertyAssetContractAddress")
	// if err != nil {
	// 	return mcp.NewToolResultText(fmt.Sprintf("Need contract address for the property. %v", err.Error())), nil
	// }
	_purchaseAmount, err := request.RequireString("purchaseAmount")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Need purchase amount for the property. %v", err.Error())), nil
	}
	purchaseAmount, err := strconv.Atoi(_purchaseAmount)
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Invalid purchase amount: %v", err.Error())), nil
	}
	e.SubscribeToProperties(purchaseAmount, signer)
	return mcp.NewToolResultText("Subscribed to purchase properties automatically"), nil
}

func (s *PropertyContract) SubscribeToProperties(purchaseAmount int, signer *evm.Signer) {
	_propertyContract, err := contract.NewProperty(s.address, s.chain.WsClient)
	oserr.WarnIfError("failed to instantiate a contract for PropertyAsset: %w", err)
	if err != nil {
		return
	}

	watchOpts := &bind.WatchOpts{Context: context.Background(), Start: nil}
	logs := make(chan *contract.PropertyAssetSold, 0)
	go func() {
		subscription, err := _propertyContract.WatchAssetSold(watchOpts, logs, make([]*big.Int, 0), make([]common.Address, 0))
		oserr.PanicIfError("failed to subscribe to PropertyAssetSold events: %w", err)
		defer subscription.Unsubscribe()
		for {
			select {
			case err := <-subscription.Err():
				log.Warn("error during subscription: %w", err)
				break
			case msg := <-logs:
				// property := NewPropertyAsset(e.client)
				// property.RefreshContract(contractAddress)
				txn, err := s.BuyProperty(msg.AssetId, int64(purchaseAmount), signer)
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
