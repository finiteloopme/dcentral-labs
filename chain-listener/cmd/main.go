package main

import (
	"github.com/finiteloopme/dcentral-labs/chain-listener/pkg/pipeline"

	"github.com/finiteloopme/dcentral-labs/chain-listener/config"
	"github.com/finiteloopme/goutils/pkg/log"
)

func main() {
	cfg, err := config.ParseAndValidate()
	if err != nil {
		log.Fatal(err)
	}

	log.Debugf("Config: %+v", cfg)
	pipeline.RunDataPipeline(cfg)
}
