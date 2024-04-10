package utils

import (
	"context"
	"fmt"

	"github.com/gagliardetto/solana-go/rpc"
	"github.com/gagliardetto/solana-go/rpc/ws"
)

type SolanaClient struct {
	rpcClient *rpc.Client
	wsClient  *ws.Client
	ctx context.Context
	commitment rpc.CommitmentType
}

func New(ctx context.Context, endpointRPC string, endpointWS string, commitment rpc.CommitmentType) *SolanaClient {
	rpcClient := rpc.New(endpointRPC)
	wsClient, err := ws.Connect(ctx, endpointWS)
	panicIfErr(err)
	return &SolanaClient{
		rpcClient: rpcClient,
		wsClient:  wsClient,
		ctx: ctx,
		commitment: commitment,
	}
}

func panicIfErr(err error, msg ...string) {
	if err != nil {
		if len(msg) > 0 {
			fmt.Println(msg)
		} else {
			fmt.Println(err.Error())
		}
		panic(err)
	}
}

type SolanaAPI interface {
	func (*SolanaClient)GetLatestBlockhash() *rpc.GetLatest
}
