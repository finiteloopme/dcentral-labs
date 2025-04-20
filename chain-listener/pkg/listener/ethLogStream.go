package listener

import (
	"context"
	"fmt"
	"reflect"
	"sync"
	"time"

	"github.com/apache/beam/sdks/v2/go/pkg/beam"
	"github.com/apache/beam/sdks/v2/go/pkg/beam/log"
	"github.com/apache/beam/sdks/v2/go/pkg/beam/register"
	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethclient"
)

// ethLogStreamFn is a Beam DoFn that connects to an Ethereum WebSocket endpoint,
// subscribes to logs for a specific contract, and emits raw logs.
// It's a simplified unbounded source; production use might need Splittable DoFn.
type ethLogStreamFn struct {
	WebsocketURL    string
	ContractAddress string
	// Removed ABI dependency - this source only deals with raw logs
	emitMu sync.Mutex
}

// newEthLogStreamFn creates a new instance of the DoFn.
func NewEthLogStreamFn(url, addr string) *ethLogStreamFn {
	return &ethLogStreamFn{
		WebsocketURL:    url,
		ContractAddress: addr,
	}
}

// ProcessElement connects, subscribes, and emits logs until the context is cancelled.
func (fn *ethLogStreamFn) ProcessElement(ctx context.Context, _ []byte, emit func(types.Log)) error {
	log.Infof(ctx, "Source: Connecting to WebSocket: %s for contract: %s", fn.WebsocketURL, fn.ContractAddress)

	// Add retry logic for initial connection
	var client *ethclient.Client
	var err error
	for i := 0; i < 5; i++ { // Retry up to 5 times
		client, err = ethclient.DialContext(ctx, fn.WebsocketURL)
		if err == nil {
			break
		}
		log.Warnf(ctx, "Source: Failed to connect (attempt %d/5): %v. Retrying in %v...", i+1, err, time.Duration(i*2)*time.Second)
		select {
		case <-time.After(time.Duration(i*2) * time.Second):
			continue
		case <-ctx.Done():
			log.Errorf(ctx, "Source: Context cancelled during connection retry.")
			return ctx.Err()
		}
	}
	if err != nil {
		log.Errorf(ctx, "Source: Failed to connect to WebSocket after retries: %v", err)
		return fmt.Errorf("ethclient.DialContext failed after retries: %w", err)
	}
	defer client.Close()
	log.Infof(ctx, "Source: Connected successfully.")

	contractAddr := common.HexToAddress(fn.ContractAddress)
	query := ethereum.FilterQuery{
		Addresses: []common.Address{contractAddr},
	}

	logs := make(chan types.Log)
	subCtx, cancelSub := context.WithCancel(ctx) // Context for the subscription loop
	defer cancelSub()                            // Ensure cancellation on function exit

	// Subscription loop with reconnection logic
	go func() {
		defer func() {
			log.Infof(subCtx, "Source: Subscription go-routine exiting.")
			close(logs) // Close channel when routine exits
		}()

		var sub ethereum.Subscription
		var subErr error

		for {
			select {
			case <-subCtx.Done():
				log.Infof(subCtx, "Source: Subscription context cancelled, stopping.")
				if sub != nil {
					sub.Unsubscribe()
				}
				return
			default:
				// Attempt subscription if not already subscribed or if connection dropped
				if sub == nil {
					log.Infof(subCtx, "Source: Attempting to subscribe to logs...")
					sub, subErr = client.SubscribeFilterLogs(subCtx, query, logs)
					if subErr != nil {
						log.Errorf(subCtx, "Source: Failed to subscribe: %v. Retrying in 5s...", subErr)
						// Simple retry delay, consider exponential backoff
						select {
						case <-time.After(5 * time.Second):
							continue // Retry subscription
						case <-subCtx.Done():
							log.Infof(subCtx, "Source: Context cancelled during subscription retry.")
							return
						}
					}
					log.Infof(subCtx, "Source: Successfully subscribed to logs.")
				}

				// Wait for subscription errors (indicates connection drop)
				select {
				case err := <-sub.Err():
					log.Errorf(subCtx, "Source: Subscription error: %v. Will attempt resubscription.", err)
					sub.Unsubscribe() // Clean up old subscription
					sub = nil         // Signal to resubscribe
					// Wait a bit before trying to resubscribe
					select {
					case <-time.After(5 * time.Second):
						continue
					case <-subCtx.Done():
						log.Infof(subCtx, "Source: Context cancelled while waiting to resubscribe.")
						return
					}
				case <-subCtx.Done():
					log.Infof(subCtx, "Source: Context cancelled while waiting on subscription.")
					if sub != nil {
						sub.Unsubscribe()
					}
					return
				}
			}
		}
	}()

	// Emit logs received from the channel
	log.Infof(ctx, "Source: Starting log emission loop.")
	for {
		select {
		case vLog, ok := <-logs:
			if !ok {
				log.Warnf(ctx, "Source: Log channel closed. Subscription might have failed permanently.")
				// Check context error to see if it was intentional shutdown
				if ctx.Err() != nil {
					return ctx.Err() // Pipeline is shutting down
				}
				// Otherwise, the subscription failed irrecoverably
				return fmt.Errorf("log subscription channel closed unexpectedly")
			}
			// Successfully received a log
			log.Debugf(ctx, "Source: Received log: Block %d, Tx %s, Index %d", vLog.BlockNumber, vLog.TxHash.Hex(), vLog.Index)
			fn.emitMu.Lock()
			emit(vLog)
			fn.emitMu.Unlock()
		case <-ctx.Done():
			// Pipeline is shutting down or main context was cancelled
			log.Infof(ctx, "Source: Main context cancelled, stopping log emission loop.")
			cancelSub() // Signal subscription goroutine to stop
			return nil  // Normal exit
		}
	}
}

func init() {
	// Register DoFn and necessary types
	register.DoFn3x1[context.Context, []byte, func(types.Log), error]((*ethLogStreamFn)(nil))
	beam.RegisterType(reflect.TypeOf((*types.Log)(nil)).Elem())
	beam.RegisterType(reflect.TypeOf((*common.Hash)(nil)).Elem())
	beam.RegisterType(reflect.TypeOf((*common.Address)(nil)).Elem())
}
