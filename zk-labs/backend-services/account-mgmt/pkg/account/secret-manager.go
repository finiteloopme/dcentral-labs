package account

import (
	"context"
	"fmt"

	"cloud.google.com/go/secretmanager/apiv1/secretmanagerpb"
	"github.com/finiteloopme/dcentral-labs/zk-labs/backend-services/account-mgmt/internal"
	"github.com/finiteloopme/goutils/pkg/log"
)

func GetSecretValue(key string) (string, error) {
	projectID := internal.GetProjectID()
	client := internal.GetSecretmanagerClient()
	ctx := context.Background()
	// Build the request.
	accessRequest := &secretmanagerpb.AccessSecretVersionRequest{
		Name: fmt.Sprintf("projects/%s/secrets/%s/versions/latest", projectID, key),
	}

	// Call the API.
	result, err := client.AccessSecretVersion(ctx, accessRequest)
	if err != nil {
		log.Warn("failed to access secret version. ", err)
		return "", err
	}

	// Print the secret payload.
	//
	// WARNING: Do not print the secret in a production environment - this
	// snippet is showing how to access the secret material.
	// log.Info(fmt.Sprintf("Plaintext: %s", result.Payload.Data))
	return string(result.Payload.Data), err
}

func DeleteSecret(key string) error {
	projectID := internal.GetProjectID()
	client := internal.GetSecretmanagerClient()
	ctx := context.Background()

	req := &secretmanagerpb.DeleteSecretRequest{
		Name: fmt.Sprintf("projects/%s/secrets/%s", projectID, key),
	}
	err := client.DeleteSecret(ctx, req)
	if err != nil {
		log.Warn("error deleting secret. ", err)
	}
	return err
}

func CreateSecret(key, payload string) error {
	projectID := internal.GetProjectID()

	// Create the request to create the secret.
	createSecretReq := &secretmanagerpb.CreateSecretRequest{
		Parent:   fmt.Sprintf("projects/%s", projectID),
		SecretId: key,
		Secret: &secretmanagerpb.Secret{
			Replication: &secretmanagerpb.Replication{
				Replication: &secretmanagerpb.Replication_Automatic_{
					Automatic: &secretmanagerpb.Replication_Automatic{},
				},
			},
		},
	}
	client := internal.GetSecretmanagerClient()
	ctx := context.Background()
	secret, err := client.CreateSecret(ctx, createSecretReq)
	if err != nil {
		log.Warn("error creating secret. ", err)
		return err
	}

	// Build the request.
	addSecretVersionReq := &secretmanagerpb.AddSecretVersionRequest{
		Parent: secret.Name,
		Payload: &secretmanagerpb.SecretPayload{
			Data: []byte(payload),
		},
	}

	// Call the API.
	_, err = client.AddSecretVersion(ctx, addSecretVersionReq)
	if err != nil {
		log.Warn("failed to add secret version. ", err)
		return err
	}

	return nil
}
