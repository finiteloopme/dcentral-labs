package svc

// import (
// 	"context"
// 	"log"
// 	"net/http"

// 	"connectrpc.com/connect"
// 	chainv1alpha1 "github.com/finiteloopme/dcentral-labs/chain-data-stream/api/gen/chain/v1alpha1"
// 	"github.com/finiteloopme/dcentral-labs/chain-data-stream/api/gen/chain/v1alpha1/chainv1alpha1connect"
// 	"github.com/finiteloopme/goutils/pkg/log"
// 	"golang.org/x/net/http2"
// 	"golang.org/x/net/http2/h2c"
// )

// type ChainServer struct {
// 	chainv1alpha1connect.UnimplementedChainReadingServiceHandler
// }

// func listenAndServe() {
// 	mux := http.NewServeMux()
// 	mux.Handle(chainv1alpha1connect.NewChainReadingServiceHandler(&ChainServer{}))

// 	err := http.ListenAndServe(
// 		"localhost:8080",
// 		h2c.NewHandler(mux, &http2.Server{}),
// 	)

// 	log.Fatal("Failed to start server: " + err)
// }

// func (cs *ChainServer) Start(
// 	ctx context.Context,
// 	req *connect.Request[chainv1alpha1.StartChainReadingRequest],
// ) (*connect.Response[chainv1alpha1.StartChainReadingResponse], error) {
// 	log.Info("In Start")

// 	return nil, nil
// }
