OUTPUT_DIR = ./bin
OUTPUT_BINARY=chain-log-listener
GCP_PROJECT=kunal-scratch
GCP_REGION=us-central1
ARTIFACT_REPO=labs
VERSION=v0.0.2

.PHONY: init
init:
	go mod tidy
	go fmt ./...


.PHONY: clean
clean:
	rm -rf $(OUTPUT_DIR)

.PHONY: test
test:
	go test -cover ./...

.PHONY: build
build:
	go build -o $(OUTPUT_DIR)/$(OUTPUT_BINARY) cmd/main.go

.PHONY: build-prod
build-prod: clean init build

.PHONY: run
run:
	go run cmd/main.go \
		--temp-local-config-filepath="/tmp/chain-listener-config.toml" \
		--remote-config-file-url="https://raw.githubusercontent.com/kunal-scratch/chain-listener-config/master/chain-listener-config.toml" \
		--runner=direct

.PHONY: run-df
run-df:
	go run cmd/main.go \
		--runner=dataflow \
		--temp-local-config-filepath="/tmp/chain-listener-config.toml" \
		--remote-config-file-url="https://raw.githubusercontent.com/kunal-scratch/chain-listener-config/master/chain-listener-config.toml" \
		--project=${GCP_PROJECT} \
		--region=${GCP_REGION} \
		--temp_location="gs://${GCP_PROJECT}/temp/" \
		--worker_machine_type=n1-standard-2 \
		--staging_location="gs://${GCP_PROJECT}/staging/" \
		--dataflow_service_options=streaming_mode_at_least_once \
		--service_account_email=550614207330-compute@developer.gserviceaccount.com \
		--async

.PHONY: docker-build
docker-build:
	  gcloud builds submit --tag ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT}/${ARTIFACT_REPO}/dataflow/${OUTPUT_BINARY}:${VERSION} .