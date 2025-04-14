package transforms

// import (
// 	"context"

// 	"github.com/apache/beam/sdks/v2/go/pkg/beam"
// 	"github.com/apache/beam/sdks/v2/go/pkg/beam/log"
// 	"github.com/apache/beam/sdks/v2/go/pkg/beam/register"
// 	"github.com/ethereum/go-ethereum/accounts/abi"
// )

// type encodeToFeeMFn struct {
// 	processedCount beam.Counter
// 	failedCount    beam.Counter
// }

// func NewEncodeToFeeMFn() *encodeToFeeMFn {
// 	return &encodeToFeeMFn{
// 		processedCount: beam.NewCounter("EncodeToFeeMFn", "processed_count"),
// 		failedCount:    beam.NewCounter("EncodeToFeeMFn", "failed_count"),
// 	}
// }

// func (fn *encodeToFeeMFn) ProcessElement(ctx context.Context, abiEvent *abi.Event, emit func(interface{})) {
// 	log.Debugf(ctx, "Encoding to FeeM event: %v", abiEvent.Name)
// 	fn.processedCount.Inc(ctx, 1)
// 	emit(abiEvent)
// }

// func registerEncodeToFeeMFn() {
// 	register.DoFn3x0[context.Context, *abi.Event, func(interface{})]((*encodeToFeeMFn)(nil))
// }
