
include envconfig.properties
ENCODED_IMG_DATA := $(shell cat unsplash-photo.png | base64 )

clean:
	cd ../basic; cargo clean
	cd ../image-processor; forge clean

build:
	cd ../image-processor; forge build
	cd ../basic; cargo build

gen-abi:
	cd ../image-processor; forge build --silent && jq '.abi' ./out/ImageProcessor.sol/ImageProcessor.json > ./out/ImageProcessor.abi
	echo "ABI written to ../image-processor/out/ImageProcessor.abi"

test: build
	cd ../basic; cargo test
	cd ../image-processor; forge test

start-chain:
	anvil
	# anvil --host ${HOST} \
	# 	--port ${PORT} \
	# 	--allow-origin * \
	# 	--chain-id ${CHAIN_ID}

deploy-contract:
	cd ../image-processor; export PRIVATE_KEY=${PRIVATE_KEY}; forge script ./script/ImageProcessor.s.sol --rpc-url ${HOST}:${PORT} --broadcast --chain ${CHAIN_ID}

run-listener:
	echo ${HOST}
	echo ${PORT}
	cd ../basic; HOST=${HOST} PORT=${PORT} cargo run

upload-image:
	# echo ${ENCODED_IMG_DATA}
	# cast send 0x59f2f1fcfe2474fd5f0b9ba1e73ca90b143eb8d0 \
	# cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
	# 	"uploadImage(string)" ${ENCODED_IMG_DATA} \
	# 	--private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d \
	# 	--rpc-url http://${HOST}:${PORT}
	cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
		"uploadImage(string)" testing \
		--private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d \
		--rpc-url http://${HOST}:${PORT}
