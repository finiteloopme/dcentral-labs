TAG=agentic-portfolio-manager
VERSION=0.0.1-alpha

.PHONY: build
build:
	docker build -t ${TAG}:${VERSION} .

.PHONY: run
run:
	docker run --net host -p 8000:8000 ${TAG}:${VERSION}

.PHONY: join
join:
	docker run -it -P ${TAG}:${VERSION} bash

.PHONY: deploy
deploy:
	gcloud run deploy capital-agent-service \
		--source . \
		--region us-central1 \
		--project kunal-scratch \
		--allow-unauthenticated \
		--port 8000
