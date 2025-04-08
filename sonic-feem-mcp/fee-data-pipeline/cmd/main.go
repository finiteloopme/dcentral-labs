package main

import (
	"context"
	"flag"
	"fmt"
	"os"

	"github.com/apache/beam/sdks/v2/go/pkg/beam"
	"github.com/apache/beam/sdks/v2/go/pkg/beam/log"
	"github.com/apache/beam/sdks/v2/go/pkg/beam/x/beamx"

	// Import your project packages
	"github.com/finiteloopme/dcentral-dev/sonic-feem-mcp/fee-data-pipeline/pkg/chain"
	"github.com/finiteloopme/dcentral-dev/sonic-feem-mcp/fee-data-pipeline/pkg/config"
	"github.com/finiteloopme/dcentral-dev/sonic-feem-mcp/fee-data-pipeline/pkg/pipeline"
)

func main() {
	// Define flags using the config package
	cfg := config.ParseFlags()

	// Validate required flags
	if err := cfg.Validate(); err != nil {
		fmt.Fprintf(os.Stderr, "Configuration error: %v\n", err)
		flag.Usage()
		os.Exit(1)
	}

	// Initialize Beam
	beam.Init()

	// --- Load Contract ABI from File ---
	ctx := context.Background() // Use background context for setup tasks
	log.Infof(ctx, "Attempting to load ABI for contract %s from file: %s", cfg.ContractAddress, cfg.ABIFilePath)

	// Call the function to load ABI from the specified file path
	parsedABI, abiString, err := chain.LoadABIFromFile(ctx, cfg.ABIFilePath)
	if err != nil {
		log.Fatalf(ctx, "Failed to load or parse ABI from file '%s': %v.", cfg.ABIFilePath, err)
	}
	log.Infof(ctx, "Successfully loaded and parsed ABI from file: %s", cfg.ABIFilePath)

	// --- Create and Run Pipeline ---
	p := beam.NewPipeline()
	s := p.Root()

	log.Infof(ctx, "Building pipeline...")

	// Build the pipeline using the function from the pipeline package
	pipeline.Build(s, cfg, abiString, parsedABI) // Pass config, ABI string, and parsed ABI

	log.Infof(ctx, "Pipeline constructed, setting Dataflow options...")

	// Set Dataflow runner options
	// Go doesn't support programatic setting of Dataflow runner options
	// Needs to be done via CLI: https://cloud.google.com/dataflow/docs/guides/setting-pipeline-options#go
	// beamx.SetPipelineOptions(p,
	// 	jobopts.Project(cfg.ProjectID),
	// 	jobopts.Region(cfg.Region),
	// 	jobopts.TempLocation(cfg.TempLocation),
	// 	jobopts.StagingLocation(cfg.StagingLocation),
	// 	jobopts.WorkerMachineType(cfg.WorkerMachineType),
	// 	jobopts.MaxNumWorkers(cfg.MaxNumWorkers),
	// 	jobopts.JobName(fmt.Sprintf("sonic-event-pipeline-%s", uuid.New().String()[:8])),
	// 	// jobopts.EnableStreamingEngine(), // Consider uncommenting for true streaming
	// )

	// Execute the pipeline using the Dataflow runner
	log.Infof(ctx, "Submitting pipeline to Dataflow...")
	if err := beamx.Run(ctx, p); err != nil {
		log.Fatalf(ctx, "Pipeline execution failed: %v", err)
	}

	log.Infof(ctx, "Pipeline execution submitted successfully (monitor on Dataflow UI).")
}
