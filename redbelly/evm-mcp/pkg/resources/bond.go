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

type BondContract struct {
	chain *evm.Chain
	// signer     *evm.Signer
	caller     *contract.BondCaller
	transactor *contract.BondTransactor
	address    common.Address
}

type BondEntity struct {
	contract.BondsContractV1Bond
	AsseId      big.Int `json:"assetId"`
	Category    string  `json:"category"`
	Description string  `json:"description"`
}

func NewBondContract(chain *evm.Chain, _contractAddress string) *BondContract {
	contractAddress := common.HexToAddress(_contractAddress)
	caller, err := contract.NewBondCaller(contractAddress, chain.Client)
	if err != nil {
		log.Warnf("failed to instantiate BondCaller: %w", err)
	}
	transactor, err := contract.NewBondTransactor(contractAddress, chain.Client)
	if err != nil {
		log.Warnf("failed to instantiate BondTransactor: %w", err)
	}
	return &BondContract{
		chain: chain,
		// signer:     signer,
		caller:     caller,
		transactor: transactor,
		address:    contractAddress,
	}
}

// func (s *BondContract) RefreshContract(_contractAddress string) error {
// 	contractAddress := common.HexToAddress(_contractAddress)
// 	caller, err := contract.NewBondCaller(contractAddress, s.chain.Client)
// 	if err != nil {
// 		log.Warnf("failed to instantiate BondCaller: %w", err)
// 		return fmt.Errorf("failed to instantiate BondCaller: %w", err)
// 	}
// 	transactor, err := contract.NewBondTransactor(contractAddress, s.chain.Client)
// 	if err != nil {
// 		log.Warnf("failed to instantiate BondTransactor: %w", err)
// 		return fmt.Errorf("failed to instantiate BondTransactor: %w", err)
// 	}
// 	s.caller = caller
// 	s.transactor = transactor
// 	s.address = contractAddress

// 	return nil
// }

func (s *BondContract) GetAllAssets(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	bonds, err := s.GetAllBonds()
	if err != nil {
		return nil, fmt.Errorf("failed to get all bonds: %w", err)
	}

	return mcp.NewToolResultText(fmt.Sprintf("%v", bonds)), nil
}

func (s *BondContract) GetAllBonds() ([]BondEntity, error) {
	bondIds, err := s.caller.GetAllAssetIds(&bind.CallOpts{})
	if err != nil {
		return nil, fmt.Errorf("failed to get all bonds: %w", err)
	}

	return s.GetBondsByIds(bondIds)
}

func (s *BondContract) GetAssetsByIds(assetIds []*big.Int) ([]BondEntity, error) {
	bonds, err := s.GetBondsByIds(assetIds)
	if err != nil {
		return nil, fmt.Errorf("failed to get bonds: %w", err)
	}
	return bonds, nil
}

func (s *BondContract) GetBondsByIds(assetIds []*big.Int) ([]BondEntity, error) {
	var bonds []BondEntity
	for _, assetId := range assetIds {
		bond, err := s.caller.GetBondsDetailsFromId(&bind.CallOpts{}, assetId)
		if err != nil {
			return nil, fmt.Errorf("failed to get bond details: %w", err)
		}
		bondEntity := BondEntity{
			AsseId:              *assetId,
			BondsContractV1Bond: bond,
			Category:            AssetTypeBond.String(),
			Description:         fmt.Sprintf("%v asset is of type (category) %v with an assetId of %v", bond.Name, AssetTypeStock.String(), assetId.String()),
		}
		bonds = append(bonds, bondEntity)
	}
	return bonds, nil
}

func (s *BondContract) GetMyAssets(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	signerPrivKey, err := request.RequireString("signer")
	if err != nil {
		return mcp.NewToolResultText("User profile hasn't been set properly to retrieve bonds.  Requires signer key to be set"), nil
	}
	signer := evm.NewSigner(signerPrivKey)
	log.Infof("Getting bonds for user: %v", signer.Address.Hex())
	bondIds, err := s.caller.GetUserAssetIds(&bind.CallOpts{}, *signer.Address)
	if err != nil {
		return nil, fmt.Errorf("failed to get bonds for user: %s. error: %w", *signer.Address, err)
	}
	if bonds, err := s.GetBondsByIds(bondIds); err != nil {
		return nil, fmt.Errorf("failed to get s.GetAssetsByIds(bondIds): %w", err)
	} else {
		return mcp.NewToolResultText(fmt.Sprintf("%v", bonds)), nil
	}
}

func (s *BondContract) Buy(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	signerPrivKey, err := request.RequireString("signer")
	if err != nil {
		return mcp.NewToolResultText("User profile hasn't been set properly to buy bonds.  Requires signer key to be set"), nil
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
	txnReceipt, err := s.BuyBond(big.NewInt(_assetId), _tokenAmount, signer)
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Error buying bond: %v", err.Error())), nil
	}
	return mcp.NewToolResultText(fmt.Sprintf("Transaction order submitted for purchasing bond is: %v", txnReceipt)), nil
}

func (s *BondContract) BuyBond(assetId *big.Int, tokenAmount int64, signer *evm.Signer) (*types.Transaction, error) {
	tx, err := s.transactor.Buy(s.chain.NewTransactionWithValue(tokenAmount, signer), assetId)
	if err != nil {
		return nil, fmt.Errorf("failed to buy bond %v: %w", assetId, err)
	}
	return tx, nil
}

func (s *BondContract) Sell(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	signerPrivKey, err := request.RequireString("signer")
	if err != nil {
		return mcp.NewToolResultText("User profile hasn't been set properly to sell bonds.  Requires signer key to be set"), nil
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
	txnReceipt, err := s.SellBond(big.NewInt(_assetId), signer)
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Error selling asset: %v", err.Error())), nil
	}
	return mcp.NewToolResultText(fmt.Sprintf("Transaction submitted for sell order of the bond is: %v", txnReceipt.Hash().Hex())), nil

}

func (s BondContract) SellBond(assetId *big.Int, signer *evm.Signer) (*types.Transaction, error) {
	tx, err := s.transactor.Sell(s.chain.NewTransaction(signer), assetId)
	if err != nil {
		return nil, fmt.Errorf("failed to sell bond %v: %w", assetId, err)
	}

	return tx, nil
}
