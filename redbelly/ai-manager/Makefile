.PHONY: install
install:
	cd adk-web; make build
	rm -fr .venv/lib/python3.10/site-packages/google/adk/cli/browser
	cp -r  adk-web/dist/agent_framework_web/browser .venv/lib/python3.10/site-packages/google/adk/cli/