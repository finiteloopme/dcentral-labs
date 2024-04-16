
# config.env will not be available in the repo
# This is env specific.
# Includes config info, per the Config struct in pkg/config/config.go
include config.env
export 

.PHONY: run
run:
	go run cli/main.go

.PHONY: test
test:
	go test ./... -v -cover 