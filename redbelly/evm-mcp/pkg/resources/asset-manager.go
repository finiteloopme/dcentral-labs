package resources

import (
	"context"
	"fmt"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/generated/contract"
	"github.com/finiteloopme/dcentral-labs/redbelly/evm-mcp/pkg/evm"
	"github.com/finiteloopme/goutils/pkg/log"
)

// RWAManager provides methods to interact with the RWA_Manager smart contract.
type RWAManager struct {
	chain   *evm.Chain
	caller  *contract.AssetManagerRWACaller // Use the generated caller
	address common.Address
}

// NewRWAManager creates a new instance of RWAManager.
// It requires an EVM chain instance and the contract address.
func NewRWAManager(chain *evm.Chain, contractAddress common.Address) (*RWAManager, error) {
	caller, err := contract.NewAssetManagerRWACaller(contractAddress, chain.Client)
	if err != nil {
		return nil, fmt.Errorf("failed to instantiate AssetManagerRWACaller: %w", err)
	}

	return &RWAManager{
		chain:   chain,
		caller:  caller,
		address: contractAddress,
	}, nil
}

// GetAllAssets calls the getAllAssets function of the RWA_Manager smart contract.
// It now returns a slice of contract.IAssetManagerAsset, which is the generated type.
func (m *RWAManager) GetAllAssets(ctx context.Context) ([]contract.IAssetManagerAsset, error) {
	log.Infof("Getting all assets as user: %v", m.chain.Signer.Address.Hex())

	assets, err := m.caller.GetAllAssets(&bind.CallOpts{Context: ctx})
	if err != nil {
		return nil, fmt.Errorf("failed to call GetAllAssets on contract %s: %w", m.address.Hex(), err)
	}
	return assets, nil
}
