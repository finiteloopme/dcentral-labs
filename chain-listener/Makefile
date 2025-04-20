OUTPUT_DIR = ./bin
OUTPUT_BINARY=chain-log-listener
SONIC_ENDPOINT=wss://sonic-rpc.publicnode.com

.PHONY: init
init:
	go mod tidy
	go fmt ./...


.PHONY: clean
clean:
	rm -rf $(OUTPUT_DIR)

.PHONY: test
test:
	go test -cover ./...

.PHONY: build
build:
	go build -o $(OUTPUT_DIR)/$(OUTPUT_BINARY) ./...

.PHONY: run
run:
	go run cmd/main.go \
		--endpoint=$(SONIC_ENDPOINT) \
		--runner=direct

.PHONY: build-prod
build-prod: clean init build