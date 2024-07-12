package internal

import (
	"context"
	"fmt"

	"cloud.google.com/go/firestore"
	secretmanager "cloud.google.com/go/secretmanager/apiv1"
	"github.com/finiteloopme/goutils/pkg/gcp"
	"github.com/finiteloopme/goutils/pkg/log"
)

// Returns client for firestore service
func GetFirestoreClient() *firestore.Client {
	projectID := GetProjectID()

	client, err := firestore.NewClient(context.Background(), projectID)
	if err != nil {
		log.Fatal(fmt.Errorf("unexpected error creating a Firestore client: %v", err))
	}

	return client
}

func GetSecretmanagerClient() *secretmanager.Client {
	// Create the client.
	ctx := context.Background()
	client, err := secretmanager.NewClient(ctx)
	if err != nil {
		log.Fatal(fmt.Errorf("failed to setup client: %v", err))
	}
	// defer client.Close()
	return client

}

// The input environment variable should hold
// the value for the target GCP Project
// Returns nil on error
func GetProjectID(prjEnvVar ...string) string {
	projectID := ""
	if len(prjEnvVar) > 0 {
		projectID = gcp.GetProjectID(prjEnvVar[0])
	} else {
		// _appConfig := &AppConfig{}
		// envconfig.Process("", _appConfig)
		// projectID = gcp.GetProjectID(_appConfig.GCPProject)
		projectID = gcp.GetProjectID()
	}

	return projectID
}
