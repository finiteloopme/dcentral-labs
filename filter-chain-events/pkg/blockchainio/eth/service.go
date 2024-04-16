package eth

import (
	"context"
	"errors"
	"time"

	"github.com/apache/beam/sdks/v2/go/pkg/beam"
	"github.com/apache/beam/sdks/v2/go/pkg/beam/core/sdf"
	"github.com/apache/beam/sdks/v2/go/pkg/beam/register"
	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/finiteloopme/dcentral-labs/filter-chain-events/pkg/filter"
	"github.com/finiteloopme/goutils/pkg/log"
)

type ethSubscriber struct {
	WebsocketURL string
	client       *EthClient
	filter       *filter.Filter
}

// register the consumer in beam framework
func init() {
	register.DoFn5x2[context.Context, beam.BundleFinalization, *sdf.LockRTracker, []byte, func(types.Log), sdf.ProcessContinuation, error](&ethSubscriber{})
	register.Emitter1[types.Log]()
}

// CreateInitialRestriction() establishes the Filter name as the
// initial restriction
func (sub *ethSubscriber) CreateInitialRestriction(_ []byte) string {
	if sub.WebsocketURL != "" && sub.filter != nil {
		return sub.filter.Filter.Name
	} else {
		return ""
	}
}

// CreateTracker wraps the Filter name in a StaticRTracker
// and applies a mutex via LockRTracker.
func (sub *ethSubscriber) CreateTracker(filterName string) *sdf.LockRTracker {
	return sdf.NewLockRTracker(NewSubscriptionRTracker(filterName))
}

// RestrictionSize always returns 1.0, as the restriction is always 1 subscription.
func (sub *ethSubscriber) RestrictionSize(_ []byte, rest string) float64 {
	return 1.0
}

// SplitRestriction is a no-op as the restriction cannot be split.
func (sub *ethSubscriber) SplitRestriction(_ []byte, filterName string) []string {
	return []string{filterName}
}

// Setup initializes ETH client if one has not been created already
func (sub *ethSubscriber) Setup(ctx context.Context) error {
	if sub.WebsocketURL != "" && sub.client == nil {
		sub.client = Connect(sub.WebsocketURL)
		sub.filter = &filter.Filter{}
	}

	return nil
}

func newEthSubscriber(wsURL string, filter filter.Filter) *ethSubscriber {
	if wsURL == "" {
		log.Warn("Websocket URL not specified. ", errors.New("expected valid websocket URL"))
	}
	_client := Connect(wsURL)
	if _client == nil {
		log.Warn("Unable to connect to: "+wsURL, errors.New("can't establish connection to the chain"))
	}
	_ethSub := &ethSubscriber{
		WebsocketURL: wsURL,
		client:       _client,
		filter:       &filter,
	}
	return _ethSub
}

func (sub *ethSubscriber) ProcessElement(ctx context.Context, bf beam.BundleFinalization, rt *sdf.LockRTracker, _ []byte, emit func(types.Log)) (sdf.ProcessContinuation, error) {
	for {
		ok := rt.TryClaim(sub.filter.Filter.Name)
		if !ok {
			// try again in 5 secs
			return sdf.ResumeProcessingIn(5 * time.Second), nil
		}
		cancelCtx, cancelFn := context.WithCancel(ctx)
		defer cancelFn()
		ethLogs := make(chan types.Log)
		ethSubscription, _ := sub.client.ethclient.SubscribeFilterLogs(cancelCtx, ethereum.FilterQuery{}, ethLogs)
		timeout := time.NewTimer(5 * time.Second)
		for {
			select {
			case err := <-ethSubscription.Err():
				log.Fatal(err)
			case m, ok := <-ethLogs:
				if !ok {
					log.Debug("stopping bundle processing")
					return sdf.StopProcessing(), nil
				}
				emit(m)
				if !timeout.Stop() {
					<-timeout.C
				}
				timeout.Reset(5 * time.Second)
			case <-timeout.C:
				log.Debug("cancelling receive context, scheduling resumption")
				cancelFn()
				return sdf.ResumeProcessingIn(10 * time.Second), nil
			}
		}
	}
}

func Read(scope beam.Scope, wsURL string, filter filter.Filter) beam.PCollection {
	scope = scope.Scope("blockchainio.eth.Read")
	ethSubscriber := newEthSubscriber(wsURL, filter)

	return beam.ParDo(
		scope,
		ethSubscriber,
		beam.Impulse(scope),
	)
}
