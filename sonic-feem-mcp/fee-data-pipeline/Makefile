BUILD_FOLDER=build
APP_BIN=sonic-feem-pipeline
GCP_PROJECT=kunal-scratch
GCP_REGION=us-central1
# wss://sonic-rpc.publicnode.com
# wss://rpc.soniclabs.com
SONIC_RPC_URL=wss://sonic-mainnet.g.alchemy.com/v2/9tRcxMiTxZ6RrFZDnPYVVZVdRXRt3z0G
TEST_DATA=./test-data

.PHONY: clean

clean:
	rm -rf ${BUILD_FOLDER}

build: 
	go mod tidy
	go build -o ${BUILD_FOLDER}/${APP_BIN} cmd/main.go

test:
	go test -v -cover ./...

run: build
	${BUILD_FOLDER}/${APP_BIN}   \
		--project=${GCP_PROJECT} \
		--runner=dataflow \
		--region=${GCP_REGION} \
		--temp_location="gs://${GCP_PROJECT}/temp/" \
		--max_num_workers=3 \
		--worker_machine_type=n2-standard-4 \
		--staging_location="gs://${GCP_PROJECT}/staging/" \
		--contract_address="0x0b5f073135df3f5671710f08b08c0c9258aecc35" \
		--websocket_url=${SONIC_RPC_URL} \
		--pubsub_topic="projects/${GCP_PROJECT}/topics/sonic_feem_mcp_events" \
		--dataflow_service_options=streaming_mode_at_least_once \
		--abi_file_path="./feem-abi.json"

r:
	go run cmd/main.go \
		--runner=direct \
		--project=${GCP_PROJECT} \
		--temp_location="gs://${GCP_PROJECT}/temp/" \
		--staging_location="gs://${GCP_PROJECT}/staging/" \
		--contract_address="0x0b5f073135df3f5671710f08b08c0c9258aecc35" \
		--websocket_url=${SONIC_RPC_URL} \
		--pubsub_topic="projects/${GCP_PROJECT}/topics/sonic_feem_mcp_events" \
		--abi_file_path="./feem-abi.json"

datagen:
	go run internal/test/datagen/ethlogs.go