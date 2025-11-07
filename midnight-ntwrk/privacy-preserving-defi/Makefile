.PHONY: help dev-start dev-stop dev-logs dev-restart dev-clean dev-status dev-build test demo-start demo-stop cloud-build cloud-deploy cloud-destroy cloud-status cloud-logs cloud-test build-compact build-midnight-integration

help:
	@echo "Privacy-Preserving DeFi MVP"
	@echo ""
	@echo "Local Development:"
	@echo "  dev-start     - Start local development services (mock proofs)"
	@echo "  dev-stop      - Stop local development services"
	@echo "  dev-logs      - Show local service logs"
	@echo "  dev-restart   - Restart local development services"
	@echo "  dev-clean     - Clean local development resources"
	@echo "  dev-status    - Show local service status"
	@echo "  dev-build     - Build all development components"
	@echo "  test          - Run tests"
	@echo ""
	@echo "Compact Contract Development:"
	@echo "  build-compact      - Build Compact contract"
	@echo "  build-midnight-integration - Build Midnight integration service"
	@echo ""
	@echo "Production Demo:"
	@echo "  demo-start    - Start production demo (real Midnight proofs)"
	@echo "  demo-stop     - Stop production demo services"
	@echo ""
	@echo "Cloud Operations:"
	@echo "  cloud-build   - Build and push application image"
	@echo "  cloud-deploy  - Deploy application and infrastructure"
	@echo "  cloud-destroy - Destroy cloud infrastructure"
	@echo "  cloud-status  - Show deployment status"
	@echo "  cloud-logs    - Show cloud service logs"
	@echo "  cloud-test    - Test deployed service"

# Development operations
dev-start:
	@./scripts/dev.sh start

dev-stop:
	@./scripts/dev.sh stop

dev-logs:
	@./scripts/dev.sh logs

dev-restart:
	@./scripts/dev.sh restart

dev-clean:
	@./scripts/dev.sh clean

dev-status:
	@./scripts/dev.sh status

dev-build:
	@./scripts/dev.sh build-compact && ./scripts/dev.sh build-midnight-integration

# Production demo operations
demo-start:
	@./scripts/dev.sh start prod

demo-stop:
	@./scripts/dev.sh stop

# Cloud operations
cloud-build:
	@./scripts/cloud.sh build

cloud-deploy:
	@./scripts/cloud.sh deploy

cloud-destroy:
	@./scripts/cloud.sh destroy

cloud-status:
	@./scripts/cloud.sh status

cloud-logs:
	@./scripts/cloud.sh logs

cloud-test:
	@./scripts/cloud.sh test

# Build operations
build-compact:
	@./scripts/dev.sh build-compact

build-midnight-integration:
	@./scripts/dev.sh build-midnight-integration

# Test operations
test:
	@./scripts/dev.sh test