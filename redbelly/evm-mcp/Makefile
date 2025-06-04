BINARY_FOLDER=bin
BINARY_NAME=evm-mcp-rwa
ABI_FOLDER=../portfolio-manager/abi

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
	go test -cover -v ./...

.PHONY: abi2go
abi2go:
	mkdir -p generated/contract
	abigen --abi ${ABI_FOLDER}/RWA_Manager.json --pkg contract --type AssetManagerRWA --out generated/contract/asset_manager_rwa.go
	abigen --abi ${ABI_FOLDER}/StockAsset.json --pkg contract --type StockAsset --out generated/contract/stock_asset.go
