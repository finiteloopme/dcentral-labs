.PHONY: setup build image-build image-submit tf-plan tf-apply tf-destroy tf-output \
       deploy-debug deploy-prod health config clean

## ---------------------------------------------------------------------------
## Prerequisites
## ---------------------------------------------------------------------------
setup:
	@bash scripts/setup.sh

## ---------------------------------------------------------------------------
## Local build
## ---------------------------------------------------------------------------
build:
	cargo build --release

## ---------------------------------------------------------------------------
## Container image
## ---------------------------------------------------------------------------
image-build:
	@bash scripts/image.sh build

image-submit:
	@bash scripts/image.sh submit

## ---------------------------------------------------------------------------
## Terraform (via Cloud Build - no local terraform needed)
## ---------------------------------------------------------------------------
tf-plan:
	@bash scripts/cloud-build.sh plan

tf-apply:
	@bash scripts/cloud-build.sh apply

tf-destroy:
	@bash scripts/cloud-build.sh destroy

tf-output:
	@bash scripts/cloud-build.sh output

## ---------------------------------------------------------------------------
## Full deploy pipelines
## ---------------------------------------------------------------------------
deploy-debug:
	@DEPLOY_ENVIRONMENT=debug bash scripts/image.sh submit
	@DEPLOY_ENVIRONMENT=debug bash scripts/cloud-build.sh apply

deploy-prod:
	@DEPLOY_ENVIRONMENT=prod bash scripts/image.sh submit
	@DEPLOY_ENVIRONMENT=prod bash scripts/cloud-build.sh apply

## ---------------------------------------------------------------------------
## Operations
## ---------------------------------------------------------------------------
health:
	@bash scripts/health.sh

config:
	@SKIP_CONFIG_LOAD=1 bash -c 'source scripts/common.sh && load_config && print_config'

## ---------------------------------------------------------------------------
## Cleanup
## ---------------------------------------------------------------------------
clean:
	cargo clean
	rm -f terraform/terraform.tfvars
