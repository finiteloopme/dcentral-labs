BINARY=chain-data-streaming
BIN_OUT=bin
PROTO_API=api

.PHONY: venv codeprep run build clean

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

build:
	go build -o ${BIN_OUT}/${BINARY} cmd/main.go
