package transforms

import (
	"context"
	"reflect"

	"github.com/apache/beam/sdks/v2/go/pkg/beam"
	"github.com/apache/beam/sdks/v2/go/pkg/beam/register"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/core/types"
)

type encodeToABIFn struct {
	// processedCount beam.Counter
	// failedCount    beam.Counter
	// duplicateCount beam.Counter
	// ignoredCount   beam.Counter

	parsedABI *abi.ABI
}

func NewEncodeToABIFn(abi *abi.ABI) *encodeToABIFn {
	return &encodeToABIFn{
		// processedCount: beam.NewCounter("EncodeToABIFn", "processed_count"),
		// failedCount:    beam.NewCounter("EncodeToABIFn", "failed_count"),
		// duplicateCount: beam.NewCounter("EncodeToABIFn", "duplicate_count"),
		// ignoredCount:   beam.NewCounter("EncodeToABIFn", "ignored_count"),

		parsedABI: abi,
	}
}

func (fn *encodeToABIFn) ProcessElement(ctx context.Context, rawLog types.Log, emit func(*abi.Event)) {
	// if fn.parsedABI == nil {
	// 	log.Errorf(ctx, "Decoder: ABI not initialized for log %s:%d", rawLog.TxHash.Hex(), rawLog.Index)
	// 	fn.failedCount.Inc(ctx, 1)
	// 	return // Should not happen if Setup worked
	// }
	// if len(rawLog.Topics) == 0 {
	// 	log.Warnf(ctx, "Decoder: Log entry %s:%d has no topics, cannot decode event.", rawLog.TxHash.Hex(), rawLog.Index)
	// 	fn.ignoredCount.Inc(ctx, 1)

	// 	return // Skip logs without topics
	// }

	// eventSig := rawLog.Topics[0] // First topic is usually the event signature hash

	// parsedEvent, err := fn.parsedABI.EventByID(eventSig)
	// if err != nil {
	// 	log.Warnf(ctx, "Decoder: Log %s:%d: No matching event found in ABI for signature %s", rawLog.TxHash.Hex(), rawLog.Index, eventSig.Hex())
	// 	fn.ignoredCount.Inc(ctx, 1)
	// 	return // Skip logs for events not in the ABI
	// }

	parsedEvent := &abi.Event{}

	emit(parsedEvent)
	// fn.processedCount.Inc(ctx, 1)
}

func registerEncodeToABIFn() {
	register.DoFn3x0[context.Context, types.Log, func(*abi.Event)]((*encodeToABIFn)(nil))
	beam.RegisterType(reflect.TypeOf((*abi.Event)(nil)).Elem())
}
