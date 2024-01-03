BINARY=chain-data-streaming
BIN_OUT=bin
PROTO_API=api

# config.env will not be available in the repo
# This is env specific.
# Includes config info, per the Config struct in pkg/config/types.go
include config.env
export 

.PHONY: venv codeprep run build clean test

clean:
	rm -fr ${PROTO_API}/gen
	rm -fr ${BIN_OUT}

# Using Nix shell to setup dev pre-reqs
venv:
	nix-shell build/shell.nix

codeprep:
	cd ${PROTO_API}/proto; buf build; cd ..; buf generate proto

run:
	go run cmd/main.go

test:
	go test -cover ./...

build:
	go build -o ${BIN_OUT}/${BINARY} cmd/main.go
