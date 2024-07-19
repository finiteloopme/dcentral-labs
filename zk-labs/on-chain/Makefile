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

deploy:
	forge script script/Contracts.s.sol:MyScript --fork-url http://localhost:8545 --broadcast
	
clean:
	forge clean