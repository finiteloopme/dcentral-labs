package account_test

import (
	"testing"

	"github.com/finiteloopme/dcentral-labs/zk-labs/backend-services/account-mgmt/pkg/account"
	"github.com/stretchr/testify/assert"
)

func TestCreateEthAccount(t *testing.T) {
	priv, pub, address := account.CreateEthAccount()
	assert.NotEmpty(t, priv, "Expected valid Private Key for the account")
	assert.NotEmpty(t, address, "Expected a valid ethereum address for the account")
	assert.NotEmpty(t, pub, "Expected a valid Public Key for the account")
}
