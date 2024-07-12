package account

import (
	"context"

	"cloud.google.com/go/firestore"
	"github.com/finiteloopme/goutils/pkg/log"
	"google.golang.org/api/iterator"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type AccountRepository struct {
	CollectionName string
	Client         *firestore.Client
}

type AccountInfo struct {
	ID      string `firestore:"id"`
	Pubkey  string `firestore:"pubkey"`
	Address string `firestore:"ethAddress"`
}

func (ar *AccountRepository) Exists() bool {
	iter := ar.Client.Collections(context.Background())
	for {
		colRef, err := iter.Next()
		if err != nil || err == iterator.Done {
			return false
		}
		if colRef.ID == ar.CollectionName {
			return true
		}
	}
}

func (ar *AccountRepository) GetOrCreateRepository() *firestore.CollectionRef {
	return ar.Client.Collection(ar.CollectionName)
}

func (ar *AccountRepository) DeleteRespository() error {
	colRef := ar.GetOrCreateRepository()
	bulkWriter := ar.Client.BulkWriter(context.Background())
	for {
		iter := colRef.Limit(1000).Documents(context.Background())
		deletedCount := 0
		for {
			doc, err := iter.Next()
			if err == iterator.Done {
				break
			}
			if err != nil {
				return err
			}
			bulkWriter.Delete(doc.Ref)
			deletedCount++
		}
		if deletedCount == 0 {
			bulkWriter.End()
			break
		}
		bulkWriter.Flush()
		// log.Info(fmt.Sprintf("Deleted %v documents from collection: %v", deletedCount, ar.CollectionName))
	}
	return nil
}

func (ar *AccountRepository) CreateUser(data *AccountInfo) error {
	docRef := ar.GetOrCreateRepository().Doc(data.ID)
	// docRef.ID = data.ID
	_, err := docRef.Create(context.Background(), data)
	if err != nil {
		log.Warn("error creating a user in Accout repo. ", err)
		return err
	}
	return nil
}

func (ar *AccountRepository) DeleteUser(id string) error {
	_, err := ar.GetOrCreateRepository().Doc(id).Delete(context.Background())
	return err
}

func (ar *AccountRepository) GetUser(id string) (*AccountInfo, error) {
	docSnapshot, err := ar.GetOrCreateRepository().Doc(id).Get(context.Background())
	if status.Code(err) == codes.NotFound {
		return nil, err
	}

	_userInfo := &AccountInfo{}
	err = docSnapshot.DataTo(_userInfo)

	return _userInfo, err
}

func (ar *AccountRepository) UpdateUser(data *AccountInfo) error {
	docRef := ar.GetOrCreateRepository().Doc(data.ID)
	// docRef.ID = data.ID
	_, err := docRef.Set(context.Background(), data)
	if err != nil {
		log.Warn("error updating a user in Accout repo. ", err)
		return err
	}
	return nil
}
