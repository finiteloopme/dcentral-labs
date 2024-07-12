package account_test

import (
	"os"
	"testing"

	"github.com/finiteloopme/dcentral-labs/zk-labs/backend-services/account-mgmt/internal"
	"github.com/finiteloopme/dcentral-labs/zk-labs/backend-services/account-mgmt/pkg/account"
	"github.com/stretchr/testify/assert"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func setUp(_ *testing.T) (*account.AccountRepository, func(t *testing.T)) {
	ar := &account.AccountRepository{}
	ar.CollectionName = "TestOnlyWillBeDeleted"
	os.Setenv("GCP_PROJECT", "kunal-scratch")
	ar.Client = internal.GetFirestoreClient()

	return ar, func(t *testing.T) {
		// flush the collection
		ar.DeleteRespository()
		ar.Client.Close()
		os.Setenv("GCP_PROJECT", "")
	}
}
func TestRepoExists(t *testing.T) {
	ar, tearDown := setUp(t)
	defer tearDown(t)

	assert.False(t, ar.Exists(), "The collection [%v] should not exists", ar.CollectionName)
}

func TestCreateRepo(t *testing.T) {
	ar, tearDown := setUp(t)
	defer tearDown(t)

	assert.NotNil(t, ar.GetOrCreateRepository(), "The collection [%v] should have been created", ar.CollectionName)
}

func TestCreateUser(t *testing.T) {
	ar, tearDown := setUp(t)
	defer tearDown(t)
	accountInfo := &account.AccountInfo{
		ID:      "test-only",
		Pubkey:  "this will be a public key",
		Address: "this will be an address",
	}
	err := ar.CreateUser(accountInfo)
	assert.NoError(t, err, "Unxpected error writing document: %v", err)
}

func TestDeleteUser(t *testing.T) {
	ar, tearDown := setUp(t)
	defer tearDown(t)
	accountInfo := &account.AccountInfo{
		ID:      "test-only",
		Pubkey:  "this will be a public key",
		Address: "this will be an address",
	}
	ar.CreateUser(accountInfo)
	err := ar.DeleteUser(accountInfo.ID)
	assert.NoError(t, err, "Unxpected error [%v] deleting document: %v", err, accountInfo.ID)
}

func TestGetUser(t *testing.T) {
	ar, tearDown := setUp(t)
	defer tearDown(t)
	expectedAccount := &account.AccountInfo{
		ID:      "test-only",
		Pubkey:  "this will be a public key",
		Address: "this will be an address",
	}
	_ = ar.CreateUser(expectedAccount)
	actualAccount, err := ar.GetUser(expectedAccount.ID)
	assert.NoError(t, err, "Unxpected error [%v] deleting document: %v", err, expectedAccount.ID)
	assert.NotEmpty(t, actualAccount, "Expected a valid reference to firestore document")
	assert.Equal(t, expectedAccount, actualAccount, "Expected %v, received %v", expectedAccount, actualAccount)
}

func TestUpdateUser(t *testing.T) {
	ar, tearDown := setUp(t)
	defer tearDown(t)

	originalAccount := &account.AccountInfo{
		ID:      "test-only",
		Pubkey:  "this will be a public key",
		Address: "this will be an address",
	}
	_ = ar.CreateUser(originalAccount)
	updatedAccount := &account.AccountInfo{
		ID:      "test-only",
		Pubkey:  "this will be a public key 1",
		Address: "this will be an address 1",
	}
	err := ar.UpdateUser(updatedAccount)
	assert.NoError(t, err, "Unxpected error [%v] updating the document: %v", err, originalAccount.ID)
	actualAccount, _ := ar.GetUser(originalAccount.ID)
	assert.NotEmpty(t, actualAccount, "Expected a valid reference to firestore document")
	assert.Equal(t, updatedAccount, actualAccount, "Expected %v, received %v", updatedAccount, actualAccount)
}

func TestUserNotFound(t *testing.T) {
	ar, tearDown := setUp(t)
	defer tearDown(t)

	expectedAccount := &account.AccountInfo{
		ID:      "test-only",
		Pubkey:  "this will be a public key",
		Address: "this will be an address",
	}
	// _ = ar.CreateUser(expectedAccount)
	actualAccount, err := ar.GetUser(expectedAccount.ID)
	assert.Error(t, err, "Expected a not found error")
	assert.Equal(t, codes.NotFound, status.Code(err), "Expected not found error. Received: %v", err)
	assert.Nil(t, actualAccount, "Expecting nil user")
}

func TestDeleteRepo(t *testing.T) {
	ar, tearDown := setUp(t)
	defer tearDown(t)
	ar.GetOrCreateRepository()
	ar.DeleteRespository()
	assert.False(t, ar.Exists(), "The collection [%v] should not exists", ar.CollectionName)
}
