package wallet

import (
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/common/hexutil"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/finiteloopme/dcentral-labs/zk-labs/backend-services/account-mgmt/internal"
	"github.com/finiteloopme/dcentral-labs/zk-labs/backend-services/account-mgmt/pkg/account"
	"github.com/finiteloopme/goutils/pkg/log"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type WalletHandler struct {
	UserRepository string `default:"users" envconfig:"USER_REPO"` // Collection in Firestore
	// Environment variable holding GCP Project
	GCPProject string `default:"GCP_PROJECT" envconfig:"GCP_PROJECT"`
}

func PubkeyToAddress(pubKey string) (common.Address, error) {
	pubKeyBytes, err := hexutil.Decode(pubKey)
	if err != nil {
		log.Warn("error decoding public key. ", err)
		return common.Address{}, err
	}
	publicKey, err := crypto.UnmarshalPubkey(pubKeyBytes)
	if err != nil {
		log.Warn("error unmarshaling public key. ", err)
		return common.Address{}, err
	}
	return crypto.PubkeyToAddress(*publicKey), nil
}

func (config *WalletHandler) CreateWallet(userID string) (*account.AccountInfo, error) {
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
