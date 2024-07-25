.PHONY=test build generate deploy clean

test:
	forge test

build:
	forge build

generate: build
	mkdir -p go/abi
	mkdir -p go/erc20
	mkdir -p go/erc721
	jq '.abi' out/nft-erc721.sol/NFT.json > ./go/abi/nft.abi
	abigen --abi=go/abi/nft.abi --pkg=erc721 --out=go/erc721/nft.go
	jq '.abi' out/zkproof-erc20.sol/ZKProof.json > ./go/abi/token.abi
	abigen --abi=go/abi/token.abi --pkg=erc20 --out=go/erc20/token.go

deploy-local:
	export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80; forge script script/Contracts.s.sol:MyScript --fork-url http://localhost:8545 --broadcast

deploy-erigon:
	export PRIVATE_KEY=0x85b97ba3fd34f012d788415e0a6bfc506b3c4816d26f18602066f7e36e5f75df; forge script script/Contracts.s.sol:MyScript --fork-url http://44.215.105.45:8545 --broadcast

clean:
	forge clean