
ABI_FOLDER=abi
.PHONY: build
build: clean test
	forge build

.PHONY: test
test:
	forge test

.PHONY: clean
clean:
	forge clean
	rm -fr ${ABI_FOLDER}

.PHONY: sim-deployment
sim-deployment:
	forge script script/DeployRWA_Manager.s.sol \
		--private-key=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
	forge script script/DeployStockERC1155.s.sol \
		--private-key=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
	forge script script/DeployStableCoinERC1155.s.sol \
		--private-key=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
	forge script script/DeploySovereignBondERC1155.s.sol \
		--private-key=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

.PHONY: deploy
deploy:
	forge script script/DeployRWA_Manager.s.sol \
		--fork-url 127.0.0.1:8545 \
		--broadcast \
		--private-key=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
	forge script script/DeployStockERC1155.s.sol \
		--fork-url 127.0.0.1:8545 \
		--broadcast \
		--private-key=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
	forge script script/DeployStableCoinERC1155.s.sol \
		--fork-url 127.0.0.1:8545 \
		--broadcast \
		--private-key=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
	forge script script/DeploySovereignBondERC1155.s.sol \
		--fork-url 127.0.0.1:8545 \
		--broadcast \
		--private-key=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

.PHONY: start-chain-mainnet
start-chain-mainnet:
	anvil --fork-url https://governors.mainnet.redbelly.network

.PHONY: start-chain
start-chain:
	anvil --fork-url https://governors.testnet.redbelly.network

.PHONY: abi
abi: build
	mkdir -p abi
	jq '.abi' out/SovereignBondERC1155.sol/SovereignBond.json > ${ABI_FOLDER}/SovereignBond.json
	jq '.abi' out/StableCoinERC1155.sol/StableCoin.json > ${ABI_FOLDER}/StableCoin.json
	jq '.abi' out/RWA_Manager.sol/RWA_Manager.json > ${ABI_FOLDER}/RWA_Manager.json
	jq '.abi' out/StockERC1155.sol/StockERC1155.json > ${ABI_FOLDER}/StockERC1155.json