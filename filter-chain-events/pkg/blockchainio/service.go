package blockchain

import (
	"github.com/apache/beam/sdks/v2/go/pkg/beam"
	"github.com/finiteloopme/dcentral-labs/filter-chain-events/pkg/filter"
)

type Service interface {
	Read(s beam.Scope) beam.PCollection
	// Starts filtering events for given filter
	RegisterFilter(filter *filter.Filter)
}
