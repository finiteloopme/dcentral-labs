package config

import (
	"flag"
	"io"
	"net/http"
	"os"

	"github.com/finiteloopme/goutils/pkg/log"
	goconfig "github.com/golobby/config/v3"
	"github.com/golobby/config/v3/pkg/feeder"
	pb "github.com/rpcpool/yellowstone-grpc/examples/golang/proto"
)

type Config struct {
	Evm    *EVMConfig
	Solana *SolanaConfig
}

type EVMConfig struct {
	Endpoint *string
	Filter   struct {
		ContractAddress *string
	}
}

type SolanaConfig struct {
	Endpoint *string
	Filter   *pb.SubscribeRequest
	Token    *string
}

func ParseAndValidate() (*Config, error) {
	// Only works with CLI flags
	config := &Config{}
	localConfigfile := "/tmp/chain-listener-config.toml"
	FetchConfigFile(
		//TODO: make this configurable via CLI arguments
		"https://gist.githubusercontent.com/kunallimaye/b3da1edac117b15c50885f2940e9aacb/raw/f4525a9335f46b94f4e0b2444076df45aebac32e/chain-listener-config.toml",
		localConfigfile,
	)
	if err := config.ParseToml(localConfigfile); err != nil {
		log.Warnf("Error parsing config.toml: %v", err)
		return nil, err
	}
	flag.Parse()
	return config, nil
}

func FetchConfigFile(fileURL string, localFilepath string) error {
	log.Debugf("Fetching config file from: %s", fileURL)
	resp, err := http.Get(fileURL)
	if resp != nil {
		defer resp.Body.Close()
	}
	if err != nil || resp.StatusCode != 200 {
		log.Warnf("Error fetching config file: %v", err)
		return err
	}

	log.Debugf("Writing config file to: %s", localFilepath)
	out, err := os.Create(localFilepath)
	if err != nil {
		log.Warnf("Error creating config file: %v", err)
		return err
	}
	defer out.Close()
	_, err = io.Copy(out, resp.Body)
	if err != nil {
		log.Warnf("Error copying config file: %v", err)
	}
	return err
}

func (c *Config) ParseToml(filename string) error {
	feeder := feeder.Toml{Path: filename}
	return goconfig.New().AddFeeder(feeder).AddStruct(c).Feed()
}
