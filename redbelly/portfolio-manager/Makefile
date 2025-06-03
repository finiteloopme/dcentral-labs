
ABI_FOLDER=abi
.PHONY: build
build: clean # test
	forge build

.PHONY: clean
clean:
	forge clean
	rm -fr ${ABI_FOLDER} broadcast cache out

.PHONY: sim-deployment
sim-deployment:
	forge script script/DeployRWA_Manager.s.sol \
		--private-key=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
	forge script script/DeployStablecoins.s.sol \
		--private-key=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
	forge script script/DeployAndRegisterSovereignBonds.s.sol \
		--private-key=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

.PHONY:deploy-rwa
deploy-rwa:
	forge script script/DeployRWA_Manager.s.sol \
		--fork-url 127.0.0.1:8545 \
		--broadcast \
		--private-key=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

.PHONY:deploy-stock
deploy-stock:
	forge script script/DeployStocks.s.sol \
		--fork-url 127.0.0.1:8545 \
		--broadcast \
		--private-key=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a

.PHONY:deploy-stable
deploy-stable:
	forge script script/DeployStablecoins.s.sol \
		--fork-url 127.0.0.1:8545 \
		--broadcast \
		--private-key=0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6

.PHONY:deploy-sovereign
deploy-sovereign:
	forge script script/DeployAndRegisterSovereignBonds.s.sol \
		--fork-url 127.0.0.1:8545 \
		--broadcast \
		--private-key=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

.PHONY: deploy-all
deploy-all: deploy-rwa deploy-stock

.PHONY: start-chain-mainnet
start-chain-mainnet:
	anvil --fork-url https://governors.mainnet.redbelly.network

.PHONY: start-chain
start-chain:
	anvil --fork-url https://governors.testnet.redbelly.network

.PHONY: abi
abi: build
	mkdir -p abi
	jq '.abi' out/RWA_Manager.sol/RWA_Manager.json > ${ABI_FOLDER}/RWA_Manager.json
	# jq '.abi' out/SovereignBond.sol/SovereignBond.json > ${ABI_FOLDER}/SovereignBond.json
	# jq '.abi' out/StableCoin.sol/Stablecoin.json > ${ABI_FOLDER}/StableCoin.json
	jq '.abi' out/StockRWA.sol/StockAsset.json > ${ABI_FOLDER}/StockAsset.json