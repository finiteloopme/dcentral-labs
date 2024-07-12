package wallet_test

import (
	"os"
	"testing"

	"github.com/finiteloopme/dcentral-labs/zk-labs/backend-services/account-mgmt/internal"
	"github.com/finiteloopme/dcentral-labs/zk-labs/backend-services/account-mgmt/pkg/account"
	"github.com/finiteloopme/dcentral-labs/zk-labs/backend-services/account-mgmt/pkg/wallet"
	"github.com/stretchr/testify/assert"
)

func setupMainTest(userId string, _ *testing.T) (*account.AccountInfo, func(*testing.T), error) {
	walletHandler := &wallet.WalletHandler{
		UserRepository: "test-only-users",
		GCPProject:     "GCP_PROJECT",
	}
	os.Setenv(walletHandler.GCPProject, "kunal-scratch")
	accInfo, err := walletHandler.CreateWallet(userId)

	return accInfo, func(t *testing.T) {
		ar := account.AccountRepository{
			CollectionName: walletHandler.UserRepository,
			Client:         internal.GetFirestoreClient(),
		}
		ar.DeleteRespository()
		account.DeleteSecret(accInfo.Pubkey)
		os.Setenv(walletHandler.GCPProject, "")
	}, err
}

func TestPubkeyToAddress(t *testing.T) {
	_, expectedPubKey, expectedAddress := account.CreateEthAccount()
	actualAddress, err := wallet.PubkeyToAddress(expectedPubKey)
	assert.NoError(t, err, "Unexpected error converting public key to ETH address")
	assert.Equal(t, actualAddress.String(), expectedAddress, "Expected %v, received %v", expectedAddress, actualAddress)
}

func TestCreateWallet(t *testing.T) {
	userId := "kunal-test"
	_, tearDown, err := setupMainTest(userId, t)
	defer tearDown(t)

	assert.NoError(t, err, "Unexpected error creating account. %v", err)
}
