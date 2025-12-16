.PHONY: build run clean

# Default image configuration
IMAGE_NAME ?= midnight-vibe-platform
IMAGE_TAG ?= latest
CONTAINER_NAME ?= midnight-dev

## build: Build the container locally using Podman
build:
	@./scripts/build-local.sh -n $(IMAGE_NAME) -t $(IMAGE_TAG)

## run: Run the container in privileged mode
run: clean
	@./scripts/run-local.sh -n $(IMAGE_NAME) -t $(IMAGE_TAG) -c $(CONTAINER_NAME)

## clean: Stop and remove containers
clean:
	@./scripts/clean.sh -c $(CONTAINER_NAME)
