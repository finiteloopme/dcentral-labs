OUTPUT_FOLDER=bin
BIN_NAME=account-mgmt
.PHONY: init clean test build run

init:
	go fmt ./...
	go mod tidy

clean:
	rm -fr ${OUTPUT_FOLDER}
	go clean -testcache

test:
	go test ./... -v -cover

build:
	go build -o ${OUTPUT_FOLDER}/${BIN_NAME} cmd/main.go 

run:
	go run cmd/main.go
	