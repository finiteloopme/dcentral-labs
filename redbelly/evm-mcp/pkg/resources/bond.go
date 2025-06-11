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
	chain      *evm.Chain
	caller     *contract.BondCaller
	transactor *contract.BondTransactor
	address    common.Address
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
		chain:      chain,
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

func (s *BondContract) GetAllBonds() ([]contract.BondsContractV1Bond, error) {
	bondIds, err := s.caller.GetAllAssetIds(&bind.CallOpts{})
	if err != nil {
		return nil, fmt.Errorf("failed to get all bonds: %w", err)
	}

	return s.GetBondsByIds(bondIds)
}

func (s *BondContract) GetAssetsByIds(assetIds []*big.Int) ([]contract.BondsContractV1Bond, error) {
	bonds, err := s.GetBondsByIds(assetIds)
	if err != nil {
		return nil, fmt.Errorf("failed to get bonds: %w", err)
	}
	return bonds, nil
}

func (s *BondContract) GetBondsByIds(assetIds []*big.Int) ([]contract.BondsContractV1Bond, error) {
	var bonds []contract.BondsContractV1Bond
	for _, assetId := range assetIds {
		bond, err := s.caller.GetBondsDetailsFromId(&bind.CallOpts{}, assetId)
		if err != nil {
			return nil, fmt.Errorf("failed to get bond details: %w", err)
		}
		bonds = append(bonds, bond)
	}
	return bonds, nil
}

func (s *BondContract) GetMyAssets(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	bondIds, err := s.caller.GetUserAssetIds(&bind.CallOpts{}, *s.chain.Signer.Address)
	if err != nil {
		return nil, fmt.Errorf("failed to get bonds for user: %s. error: %w", *s.chain.Signer.Address, err)
	}
	if bonds, err := s.GetBondsByIds(bondIds); err != nil {
		return nil, fmt.Errorf("failed to get s.GetAssetsByIds(bondIds): %w", err)
	} else {
		return mcp.NewToolResultText(fmt.Sprintf("%v", bonds)), nil
	}
}

func (s *BondContract) Buy(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
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
	txnReceipt, err := s.BuyBond(big.NewInt(_assetId), _tokenAmount)
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Error buying bond: %v", err.Error())), nil
	}
	return mcp.NewToolResultText(fmt.Sprintf("Transaction receipt for purchased bond is: %v", txnReceipt)), nil
}

func (s *BondContract) BuyBond(assetId *big.Int, tokenAmount int64) (*types.Receipt, error) {
	tx, err := s.transactor.Buy(s.chain.NewTransactionWithValue(tokenAmount), assetId)
	if err != nil {
		return nil, fmt.Errorf("failed to buy bond %v: %w", assetId, err)
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

func (s *BondContract) Sell(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	assetId, err := request.RequireString("assetId")
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Asset ID is required: %v", err.Error())), nil
	}
	_assetId, err := strconv.ParseInt(assetId, 10, 64)
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Invalid asset ID: %v", err.Error())), nil
	}
	txnReceipt, err := s.SellBond(big.NewInt(_assetId))
	if err != nil {
		return mcp.NewToolResultText(fmt.Sprintf("Error selling asset: %v", err.Error())), nil
	}
	return mcp.NewToolResultText(fmt.Sprintf("Transaction receipt for the sold bond is: %v", txnReceipt)), nil

}

func (s BondContract) SellBond(assetId *big.Int) (*types.Receipt, error) {
	tx, err := s.transactor.Sell(s.chain.NewTransaction(), assetId)
	if err != nil {
		return nil, fmt.Errorf("failed to sell bond %v: %w", assetId, err)
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
