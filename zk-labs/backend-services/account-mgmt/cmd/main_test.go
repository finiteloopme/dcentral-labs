package main

import (
	"os"
	"testing"

	"github.com/finiteloopme/dcentral-labs/zk-labs/backend-services/account-mgmt/internal"
	"github.com/finiteloopme/dcentral-labs/zk-labs/backend-services/account-mgmt/pkg/account"
	"github.com/stretchr/testify/assert"
)

func setupMainTest(userId string, _ *testing.T) (*account.AccountInfo, error, func(*testing.T)) {
	appCfg := &AppConfig{
		UserRepository: "test-only-users",
		GCPProject:     "GCP_PROJECT",
	}
	os.Setenv(appCfg.GCPProject, "kunal-scratch")
	accInfo, err := appCfg.CreateAccount(userId)

	return accInfo, err, func(t *testing.T) {
		ar := account.AccountRepository{
			CollectionName: appCfg.UserRepository,
			Client:         internal.GetFirestoreClient(),
		}
		ar.DeleteRespository()
		account.DeleteSecret(accInfo.Pubkey)
		os.Setenv(appCfg.GCPProject, "")
	}
}
func TestCreateUser(t *testing.T) {
	userId := "kunal-test"
	_, err, tearDown := setupMainTest(userId, t)
	defer tearDown(t)

	assert.NoError(t, err, "Unexpected error creating account. %v", err)
}
