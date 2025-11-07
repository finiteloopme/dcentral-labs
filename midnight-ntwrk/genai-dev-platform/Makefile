.PHONY: build run stop clean status logs help db restart

# All operations through single modular script
build run stop clean status logs help db restart:
	@./scripts/local.sh $(firstword $(MAKECMDGOALS))

# Default target
.DEFAULT_GOAL := help