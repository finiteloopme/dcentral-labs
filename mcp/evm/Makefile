.PHONY: all build run stop fork-chain clean test

all: build

build: build-trader

build-trader:
	cd defi-trader && cargo build

run: run-trader

run-trader:
	cd defi-trader && cargo run &

stop: stop-trader

stop-trader:
	pkill -f 'defi-trader'

fork-chain:
	anvil --fork-url https://1rpc.io/eth

test:

clean: clean-trader

clean-trader:
	cd defi-trader && cargo clean