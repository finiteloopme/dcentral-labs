include config.properties
INFRA_FOLDER=./infra
APP_FOLDER=./app

.dummy: infra-init, infra-plan, infra-deploy, infra-undeploy, app-init, app-deploy, app-undeploy

infra-init:
	cd ${INFRA_FOLDER}; make init

infra-plan:
	cd ${INFRA_FOLDER}; make plan

infra-deploy:
	cd ${INFRA_FOLDER}; make deploy

infra-undeploy:
	cd ${INFRA_FOLDER}; make undeploy

app-init:
	cd ${APP_FOLDER}; make init

app-deploy:
	cd ${APP_FOLDER}; make deploy

app-undeploy:
	cd ${APP_FOLDER}; make undeploy