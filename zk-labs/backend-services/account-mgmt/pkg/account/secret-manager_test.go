package account_test

import (
	"os"
	"testing"

	// "github.com/finiteloopme/dcentral-labs/zk-labs/backend-services/account-mgmt/internal"

	"github.com/finiteloopme/dcentral-labs/zk-labs/backend-services/account-mgmt/pkg/account"
	"github.com/stretchr/testify/assert"
)

func setupSecretmanagerTest(key, value string, _ *testing.T) func(key string, t *testing.T) {
	os.Setenv("GCP_PROJECT", "kunal-scratch")
	if key != "" {
		account.CreateSecret(key, value)
	}
	return func(key string, t *testing.T) {
		// tear down test
		if key != "" {
			// Check that secret exists, else delete returns an err
			if val, err := account.GetSecretValue(key); val != "" && err == nil {
				account.DeleteSecret(key)
			}
		}
		os.Setenv("GCP_PROJECT", "")
	}
}
func TestCreateSecret(t *testing.T) {
	key := "secret-key"
	value := "secret-value"
	teardown := setupSecretmanagerTest("", "", t)
	defer teardown(key, t)

	err := account.CreateSecret(key, value)
	assert.NoError(t, err, "Unexpected error creating secret. %v", err)
}
func TestGetSecretVal(t *testing.T) {
	key := "secret-key"
	expected := "secret-value"
	teardown := setupSecretmanagerTest(key, expected, t)
	defer teardown(key, t)

	actual, err := account.GetSecretValue(key)
	assert.NoError(t, err, "Unexpected error getting secret. %v", err)
	assert.Equal(t, expected, actual, "Expected value %v, received %v", expected, actual)
}

func TestDeleteSecret(t *testing.T) {
	key := "secret-key"
	expected := "secret-value"
	teardown := setupSecretmanagerTest(key, expected, t)
	defer teardown("", t)

	err := account.DeleteSecret(key)
	assert.NoError(t, err, "Unexpected error deleting secret. %v", err)
}
