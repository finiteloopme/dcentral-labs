package main

import (
	"github.com/finiteloopme/goutils/pkg/log"
	"github.com/kelseyhightower/envconfig"
)

type AppConfig struct {
	UserRepository string `default:"users" envconfig:"USER_REPO"` // Collection in Firestore
	// Environment variable holding GCP Project
	GCPProject string `default:"GCP_PROJECT" envconfig:"GCP_PROJECT"`
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
