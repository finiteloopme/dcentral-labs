package internal_test

import (
	"os"
	"testing"

	"github.com/finiteloopme/dcentral-labs/zk-labs/backend-services/account-mgmt/internal"
	"github.com/stretchr/testify/assert"
)

func TestGetFirestoreClient(t *testing.T) {
	environmentVariable := "GCP_PROJECT"
	os.Setenv(environmentVariable, "kunal-scratch")
	client := internal.GetFirestoreClient()
	defer client.Close()

	assert.NotNil(t, client, "Expected a valid client for Firestore")
	os.Setenv(environmentVariable, "")
}

func TestSecretmanagerClient(t *testing.T) {
	// environmentVariable := "GCP_PROJECT"
	// os.Setenv(environmentVariable, "kunal-scratch")
	client := internal.GetSecretmanagerClient()
	defer client.Close()

	assert.NotNil(t, client, "Expected a valid client for Secretmanager")
	// os.Setenv(environmentVariable, "")
}

func TestGetProjectID(t *testing.T) {
	envVar := "GCP_TEST_PROJECT"
	expected := "kunal-scratch"
	os.Setenv(envVar, expected)
	val := internal.GetProjectID(envVar)
	assert.Equal(t, expected, val, "GCP project expected %v, but received %v", expected, val)

	val = internal.GetProjectID()
	assert.Empty(t, val, "GCP project expected empty, but received %v", expected, val)
}
