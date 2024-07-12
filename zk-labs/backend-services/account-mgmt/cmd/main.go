package main

import (
	"github.com/finiteloopme/dcentral-labs/zk-labs/backend-services/account-mgmt/internal"
	"github.com/finiteloopme/dcentral-labs/zk-labs/backend-services/account-mgmt/pkg/account"
	"github.com/finiteloopme/goutils/pkg/log"
	"github.com/kelseyhightower/envconfig"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type AppConfig struct {
	UserRepository string `default:"users" envconfig:"USER_REPO"` // Collection in Firestore
	// Environment variable holding GCP Project
	GCPProject string `default:"GCP_PROJECT" envconfig:"GCP_PROJECT_VAR"`
}

func (config *AppConfig) CreateAccount(userID string) (*account.AccountInfo, error) {
	ar := &account.AccountRepository{
		CollectionName: config.UserRepository,
		Client:         internal.GetFirestoreClient(),
	}

	if !ar.Exists() {
		ar.GetOrCreateRepository()
	}

	userInfo, err := ar.GetUser(userID)
	// Ignore not found
	if err != nil && status.Code(err) != codes.NotFound {
		log.Warn("error getting user from firestore. ", err)
		return nil, err
	}

	// Check if user exists
	if userInfo == nil {
		userInfo = &account.AccountInfo{ID: userID}
		err = ar.CreateUser(userInfo)
		if err != nil {
			log.Warn("error creating user account. ", err)
			return nil, err
		}
	}

	if userInfo.Pubkey == "" {
		// User doesn't have an ETH wallet, create one
		var secretKey string
		secretKey, userInfo.Pubkey, userInfo.Address = account.CreateEthAccount()
		account.CreateSecret(userInfo.Pubkey, secretKey)
		err := ar.UpdateUser(userInfo)
		if err != nil {
			log.Warn("error updating user in repo. ", err)
			return nil, err
		}
	}

	return userInfo, nil
}

// func CollectTokens() {

// }

// func CollectNFT() {

// }

func main() {
	var appConfig AppConfig
	envconfig.Process("", &appConfig)
	log.Info("In main")
}
