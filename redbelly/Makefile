TAG=agentic-portfolio-manager
VERSION=0.0.3-alpha

.PHONY: build
build:
	cd ai-manager; make install
	docker build -t ${TAG}:${VERSION} .

.PHONY: run
run:
	docker run --volume ~/.config/gcloud/application_default_credentials.json:/root/.config/gcloud/application_default_credentials.json:ro --net host -p 8000:8000 ${TAG}:${VERSION}

.PHONY: join
join:
	docker run -it -P ${TAG}:${VERSION} bash

.PHONY: deploy
deploy:
	gcloud run deploy agentic-wallet-deca \
		--source . \
		--region us-central1 \
		--project kunal-scratch \
		--allow-unauthenticated \
		--port 8000
