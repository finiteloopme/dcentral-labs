include ../config.properties

.dummy: init, deploy, undeploy

init:
	gcloud container clusters get-credentials config-cluster \
		--location=${GCP_REGION} \
		--project=${PROJECT_ID}

deploy:
	kubectl apply -f ./k8s-config/

undeploy:
	kubectl delete -f ./k8s-config/
