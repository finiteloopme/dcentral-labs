include config.properties
INFRA_FOLDER=./infra

.dummy: infra-init, infra-plan, infra-deploy, infra-undeploy

infra-init:
	cd ${INFRA_FOLDER}; make init

infra-plan:
	cd ${INFRA_FOLDER}; make plan

infra-deploy:
	cd ${INFRA_FOLDER}; make deploy

infra-undeploy:
	cd ${INFRA_FOLDER}; make undeploy