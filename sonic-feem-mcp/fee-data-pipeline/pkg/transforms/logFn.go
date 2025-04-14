package transforms

// import (
// 	"context"
// 	"reflect"

// 	"github.com/apache/beam/sdks/v2/go/pkg/beam"
// 	"github.com/apache/beam/sdks/v2/go/pkg/beam/log"
// 	"github.com/apache/beam/sdks/v2/go/pkg/beam/register"
// )

// type logFn struct {
// 	processedCount beam.Counter
// 	failedCount    beam.Counter
// }

// func NewLogFn() *logFn {
// 	return &logFn{
// 		processedCount: beam.NewCounter("LogFn", "processed_count"),
// 		failedCount:    beam.NewCounter("LogFn", "failed_count"),
// 	}
// }

// func (fn *logFn) ProcessElement(ctx context.Context, msg string, logLevel string, emit func(string)) {
// 	switch logLevel {
// 	case "INFO":
// 		log.Info(ctx, msg)
// 	case "WARNING":
// 		log.Warn(ctx, msg)
// 	case "ERROR":
// 		log.Error(ctx, msg)
// 	case "DEBUG":
// 		log.Debug(ctx, msg)
// 	default:
// 		log.Infof(ctx, "Unknown log level: '%s' for msg: '%s'", logLevel, msg)
// 		emit(msg)
// 		fn.failedCount.Inc(ctx, 1)
// 		return
// 	}
// 	emit(msg)
// 	fn.processedCount.Inc(ctx, 1)
// }

// func registerLogFn() {
// 	register.DoFn4x0[context.Context, string, string, func(string)]((*logFn)(nil))
// 	beam.RegisterType(reflect.TypeOf((*logFn)(nil)).Elem())
// }
