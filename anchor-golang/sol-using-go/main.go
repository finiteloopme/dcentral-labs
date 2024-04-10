package main

import (
	"context"
	"fmt"

	"github.com/finiteloopme/dcentral-labs/anchor-golang/sol-using-go/generated/counter_prg"
	"github.com/gagliardetto/solana-go"
	"github.com/gagliardetto/solana-go/programs/system"
	"github.com/gagliardetto/solana-go/rpc"
	confirm "github.com/gagliardetto/solana-go/rpc/sendAndConfirmTransaction"
	"github.com/gagliardetto/solana-go/rpc/ws"
)

func main() {
	// client, err := ws.Connect(context.Background(), rpc.DevNet.RPC)
	client := rpc.New(rpc.DevNet.RPC)
	// Create a new WS client (used for confirming transactions)
	wsClient, err := ws.Connect(context.Background(), rpc.DevNet_WS)
	if err != nil {
		panic(err)
	}

	// Who will pay for the transactions
	payee, err := solana.PrivateKeyFromSolanaKeygenFile("/Users/kunall/.config/solana/id.json")
	fmt.Println("Payee wallet: " + payee.PublicKey().String())
	panicIfErr("Error reading user wallet", err)

	// New account to store counter state
	counterStore := solana.NewWallet()
	fmt.Println("Counter store: " + counterStore.PublicKey().String())

	// Initialize counter
	instruction := counter_prg.NewInitializeInstruction(10,
		counterStore.PublicKey(),
		payee.PublicKey(),
		system.ProgramID,
	).Build()
	blockhash, err := client.GetLatestBlockhash(context.TODO(), rpc.CommitmentFinalized)
	panicIfErr("Error getting latest block hash", err)

	txn, _ := solana.NewTransaction([]solana.Instruction{instruction}, blockhash.Value.Blockhash, solana.TransactionPayer(payee.PublicKey()))
	_, err = txn.Sign(
		func(key solana.PublicKey) *solana.PrivateKey {
			if payee.PublicKey().Equals(key) {
				return &payee
			}
			if counterStore.PublicKey().Equals(key) {
				return &counterStore.PrivateKey
			}
			return nil
		},
	)
	panicIfErr("Error creating new txn", err)
	sig, err := confirm.SendAndConfirmTransaction(
		context.TODO(),
		client,
		wsClient,
		txn,
	)
	panicIfErr("Error sending txn", err)
	fmt.Println("Transaction is: " + sig.String())

	blockhash, _ = client.GetLatestBlockhash(context.TODO(), rpc.CommitmentFinalized)
	txn, _ = solana.NewTransaction(
		[]solana.Instruction{counter_prg.NewIncrementInstruction(counterStore.PublicKey()).Build()},
		blockhash.Value.Blockhash,
		solana.TransactionPayer(payee.PublicKey()),
	)
	_, err = txn.Sign(
		func(key solana.PublicKey) *solana.PrivateKey {
			if payee.PublicKey().Equals(key) {
				return &payee
			}
			if counterStore.PublicKey().Equals(key) {
				return &counterStore.PrivateKey
			}
			return nil
		},
	)
	// Pretty print the transaction:
	fmt.Println(txn.String())
	sig, err = confirm.SendAndConfirmTransaction(
		context.TODO(),
		client,
		wsClient,
		txn,
	)
	// sig, err := client.SimulateTransaction(context.Background(), txn)
	panicIfErr("Error sending txn", err)
	fmt.Println("Transaction is: " + sig.String())

}

func panicIfErr(msg string, err error) {
	if err != nil {
		fmt.Println(msg)
		panic(err)
	}
}
