
# config.env will not be available in the repo
# This is env specific.
# Includes config info, per the Config struct in pkg/config/config.go

.PHONY: init
init: 
	go mod tidy
	go fmt ./...

.PHONY: run
run:
	go run cli/main.go --project=kunal-scratch --runner=dataflow --staging_location=gs://kunal-scratch/df/blockchainio
	
.PHONY: test
test:
	go test ./... -v -cover 