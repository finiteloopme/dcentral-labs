
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
	forge script script/DeployAAPL.s.sol
	forge script script/DeployRWAAssetManager.s.sol

.PHONY: deploy
deploy:
	forge script script/DeployAAPL.s.sol \
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
	jq '.abi' out/DeployRWAAssetManager.s.sol/DeployRWAAssetManager.json > ${ABI_FOLDER}/RWAAssetManager.json
	jq '.abi' out/DeployAAPL.s.sol/DeployAAPL.json > ${ABI_FOLDER}/AAPL.json