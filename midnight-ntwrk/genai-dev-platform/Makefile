.PHONY: build run stop clean status logs help db restart exec

# All operations through single modular script
build run stop clean status logs help db restart exec:
	@./scripts/local.sh $(firstword $(MAKECMDGOALS)) $(filter-out $@,$(MAKECMDGOALS))

# Default target
.DEFAULT_GOAL := help