BINARY_FOLDER=bin
BINARY_NAME=evm-mcp-rwa

.PHONY: init
init:
	go mod tidy
	go fmt ./...

.PHONY: clean
clean:
	rm -fr ${BINARY_FOLDER}

.PHONY: build
build:
	go build -o ${BINARY_FOLDER}/${BINARY_NAME} cmd/main.go

.PHONY: run
run:
	go run cmd/main.go

.PHONY: test
test:
	go test -cover -v