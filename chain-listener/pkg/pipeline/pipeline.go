package pipeline

import (
	"context"

	"github.com/apache/beam/sdks/v2/go/pkg/beam"
	"github.com/apache/beam/sdks/v2/go/pkg/beam/log"
	"github.com/apache/beam/sdks/v2/go/pkg/beam/x/beamx"
	"github.com/apache/beam/sdks/v2/go/pkg/beam/x/debug"
	"github.com/finiteloopme/dcentral-labs/chain-listener/config"
	"github.com/finiteloopme/dcentral-labs/chain-listener/pkg/listener"
)

func Build(s beam.Scope, ctx context.Context, cfg *config.Config) {
	s = s.Scope("ListenToChainLogs")

	ethLogStreamFn := listener.NewEthLogStreamFn(cfg.Endpoint, cfg.ContractAddress)
	log.Infof(ctx, "Building pipeline with DoFn: %T", ethLogStreamFn)

	rawLogs := beam.ParDo(s, ethLogStreamFn, beam.Impulse(s.Scope("Impulse")))
	debug.Printf(s.Scope("Debug"), "Raw logs: %v", rawLogs)
}

func RunDataPipeline(cfg *config.Config) {
	// Initialize Beam
	beam.Init()
	ctx := context.Background() // Use background context for setup tasks

	// --- Create and Run Pipeline ---
	p := beam.NewPipeline()
	s := p.Root()

	log.Infof(ctx, "Building pipeline...")
	// Build the pipeline
	Build(s, ctx, cfg)
	log.Infof(ctx, "Pipeline constructed, setting Dataflow options...")

	// Execute the pipeline using the Dataflow runner
	log.Infof(ctx, "Submitting pipeline to Dataflow...")
	if err := beamx.Run(ctx, p); err != nil {
		log.Fatalf(ctx, "Pipeline execution failed: %v", err)
	}

	log.Infof(ctx, "Pipeline execution submitted successfully (monitor on Dataflow UI).")

}
