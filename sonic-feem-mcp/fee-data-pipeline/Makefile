BUILD_FOLDER=build
APP_BIN=sonic-feem-pipeline
GCP_PROJECT=kunal-scratch
GCP_REGION=us-central1
# wss://sonic-rpc.publicnode.com
# wss://rpc.soniclabs.com
SONIC_RPC_URL=wss://sonic-rpc.publicnode.com

.PHONY: clean

clean:
	rm -rf ${BUILD_FOLDER}

build: 
	go mod tidy
	go build -o ${APP_BIN} cmd/main.go

test:
	go test -v -cover ./...

run: build
	./${APP_BIN}   \
		--project=${GCP_PROJECT} \
		--runner=dataflow \
		--gcp_project=${GCP_PROJECT} \
		--gcp_region=${GCP_REGION} \
		--temp_location="gs://${GCP_PROJECT}/temp/" \
		--max_num_workers=3 \
		--staging_location="gs://${GCP_PROJECT}/staging/" \
		--contract_address="0x0b5f073135df3f5671710f08b08c0c9258aecc35" \
		--abi_file_path="./feem-abi.json" \ 
		--bq_dataset="kunal-scratch.sonic-feem" \
		--bq_table="feem-events" \
		--bq_duplicate_table="feem-events-duplicates" \
		--websocket_url=${SONIC_RPC_URL}

r:
	go run cmd/main.go \
		--runner=direct \
		--gcp_project=${GCP_PROJECT} \
		--gcp_region=${GCP_REGION} \
		--temp_location="gs://${GCP_PROJECT}/temp/" \
		--staging_location="gs://${GCP_PROJECT}/staging/" \
		--contract_address="0x0b5f073135df3f5671710f08b08c0c9258aecc35" \
		--abi_file_path="./feem-abi.json" \ 
		--bq_dataset="kunal-scratch.sonic-feem" \
		--bq_table="feem-events" \
		--bq_duplicate_table="feem-events-duplicates" \
		--websocket_url=${SONIC_RPC_URL}
