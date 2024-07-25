OUTPUT_FOLDER=bin
BIN_NAME=item-collected
.PHONY: init clean test build run depy

init:
	go fmt ./...
	go mod tidy

clean:
	rm -fr ${OUTPUT_FOLDER}
	go clean -testcache

test:
	go test ./... -v -cover

build:
	go build -o ${OUTPUT_FOLDER}/${BIN_NAME} cmd/main.go 

run:
	go run cmd/main.go

deploy:
	gcloud run deploy ${BIN_NAME} \
		--source . \
		--region=us-central1 \
		--allow-unauthenticated \
		--min-instances=1