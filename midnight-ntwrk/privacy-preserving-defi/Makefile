.PHONY: help dev-start dev-stop dev-logs dev-restart dev-clean test demo-start demo-stop cloud-build cloud-deploy cloud-destroy

help:
	@echo "Privacy-Preserving DeFi MVP"
	@echo ""
	@echo "Local Development:"
	@echo "  dev-start     - Start local development services (mock proofs)"
	@echo "  dev-stop      - Stop local development services"
	@echo "  dev-logs      - Show local service logs"
	@echo "  dev-restart   - Restart local development services"
	@echo "  dev-clean     - Clean local development resources"
	@echo "  test          - Run tests"
	@echo ""
	@echo "Production Demo:"
	@echo "  demo-start    - Start production demo (real Midnight proofs)"
	@echo "  demo-stop     - Stop production demo services"
	@echo ""
	@echo "Cloud Operations (via Cloud Build):"
	@echo "  cloud-build   - Build and push application image"
	@echo "  cloud-deploy  - Deploy application and infrastructure"
	@echo "  cloud-destroy - Destroy cloud infrastructure"

dev-start:
	@./scripts/dev-start.sh

dev-stop:
	@./scripts/dev-stop.sh

dev-logs:
	@./scripts/dev-logs.sh

dev-restart: dev-stop dev-start

dev-clean:
	@./scripts/dev-clean.sh

test:
	@./scripts/test.sh

demo-start:
	@./scripts/demo-start.sh

demo-stop:
	@cd cicd && podman-compose -f docker-compose.prod.yml down

cloud-build:
	@./scripts/cloud-build.sh

cloud-deploy:
	@./scripts/cloud-deploy.sh

cloud-destroy:
	@./scripts/cloud-destroy.sh