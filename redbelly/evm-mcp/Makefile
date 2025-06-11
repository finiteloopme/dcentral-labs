BINARY_FOLDER=bin
BINARY_NAME=evm-mcp-rwa
ABI_FOLDER_LOCAL=../portfolio-manager/abi
ABI_FOLDER=abi

.PHONY: init
init:
	go mod tidy
	go fmt ./...

.PHONY: clean
clean:
	rm -fr ${BINARY_FOLDER} generated

.PHONY: build
build:
	go build -o ${BINARY_FOLDER}/${BINARY_NAME} cmd/main.go

.PHONY: run
run:
	echo "key: ${USER_PRIVATE_KEY}"
	go run cmd/main.go

.PHONY: test
test:
	go test -cover -v ./...

.PHONY: abi2go
abi2go:
	mkdir -p generated/contract
	abigen --abi ${ABI_FOLDER}/alternate.json --pkg contract --type Alternate --out generated/contract/alternate.go
	abigen --abi ${ABI_FOLDER}/bond.json --pkg contract --type Bond --out generated/contract/bond.go
	abigen --abi ${ABI_FOLDER}/equity.json --pkg contract --type Equity --out generated/contract/equity.go
	abigen --abi ${ABI_FOLDER}/property.json --pkg contract --type Property --out generated/contract/property.go
