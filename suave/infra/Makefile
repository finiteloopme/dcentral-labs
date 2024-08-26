include ../config.properties

.dummy: prep, init, plan, deploy, undeploy

define TF_ARGS
-var='project_id=${PROJECT_ID}' -var='gcp_region=${GCP_REGION}' -var='app_name=${APP_NAME}'
endef

prep:
	sed -i '' 's/${TF_BUCKET}/${PROJECT_ID}/' provider.tf
	sed -i '' 's/${TF_STATE_PREFIX}/${APP_NAME}/' provider.tf

init: prep
	terraform init

plan:
	terraform plan ${TF_ARGS}

deploy:
	terraform apply ${TF_ARGS} -auto-approve

undeploy:
	terraform destroy ${TF_ARGS} -auto-approve