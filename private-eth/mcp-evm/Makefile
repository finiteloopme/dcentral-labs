.PHONY: build run deploy clean build-agent run-agent

# Local Development

clean:
	cd server && cargo clean
	cd agent && cargo clean

build:
	cd server && cargo build

run:
	cd server && cargo run

build-agent:
	cd agent && cargo build

run-agent:
	cd agent && cargo run

# Remote Deployment

build-remote:
	gcloud builds submit --config cloudbuild.yaml

deploy-remote:
	gcloud run deploy --config cloudrun.yaml
