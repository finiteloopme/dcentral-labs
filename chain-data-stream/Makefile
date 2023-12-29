BINARY=chain-data-streaming
BIN_OUT=bin

.PHONY: venv, run, build, clean

clean:
	rm -fr ${BIN_OUT}

# Using Nix shell to setup dev pre-reqs
venv:
	nix-shell build/shell.nix

run:
	go run cmd/main.go

build:
	go build -o ${BIN_OUT}/${BINARY} cmd/main.go