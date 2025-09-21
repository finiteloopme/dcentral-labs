# Makefile for the Delegated Agent Demo

# Go settings

GO := go
GO_MOD_TIDY := $(GO) mod tidy
GO_RUN := $(GO) run

# Solidity settings

SOLC := solc
ABIGEN := abigen

# Directories

CONTRACTS_DIR := contracts
CONTRACT_BUILD_DIR := $(CONTRACTS_DIR)/out
BINDINGS_DIR := pkg/chain/bindings
DEPLOYMENTS_DIR := deployments
GO_BUILD := bin

# Contract names (must match file names without .sol)

CONTRACTS := AgentProxy TokenUSDC

# Phony targets

.PHONY: all install-deps update-forge-deps compile-contracts gen-bindings bindings compile-go build run-user-setup run-agent clean

all: build

# ==============================================================================

# GO

# ==============================================================================

install-deps:
	@echo "==> Installing Go dependencies..."
	$(GO_MOD_TIDY)

compile-go: install-deps
	$(GO) build -o $(GO_BUILD)/agent ./cmd/agent
	$(GO) build -o $(GO_BUILD)/user ./cmd/user

# ==============================================================================

# SOLIDITY & ABIGEN

# ==============================================================================

update-forge-deps:
	@echo "==> Installing/Updating contract dependencies..."
	@if [ ! -d "$(CONTRACTS_DIR)/lib/openzeppelin-contracts" ]; then \
		git clone https://github.com/OpenZeppelin/openzeppelin-contracts $(CONTRACTS_DIR)/lib/openzeppelin-contracts; \
	fi
	@rm -rf $(CONTRACTS_DIR)/lib/openzeppelin-contracts/certora
	@rm -rf $(CONTRACTS_DIR)/lib/openzeppelin-contracts/test

compile-contracts: update-forge-deps
	@echo "==> Compiling Solidity contracts..."
	@mkdir -p $(CONTRACT_BUILD_DIR)
	forge build --root $(CONTRACTS_DIR) --extra-output-files abi --extra-output-files bin

test-contracts:
	@echo "==> Testing Solidity contracts..."
	@cd $(CONTRACTS_DIR) && forge test

gen-bindings: compile-contracts
	@echo "==> Generating Go bindings for contracts..."
	@mkdir -p $(BINDINGS_DIR)
	$(ABIGEN) --abi=$(CONTRACT_BUILD_DIR)/AgentProxy.sol/AgentProxy.abi.json --bin=$(CONTRACT_BUILD_DIR)/AgentProxy.sol/AgentProxy.bin --pkg=bindings --type=Agent --out=$(BINDINGS_DIR)/agentproxy.go
	$(ABIGEN) --abi=$(CONTRACT_BUILD_DIR)/TokenUSDC.sol/TokenUSDC.abi.json --bin=$(CONTRACT_BUILD_DIR)/TokenUSDC.sol/TokenUSDC.bin --pkg=bindings --type=TokenUSDC --out=$(BINDINGS_DIR)/tokenusdc.go

# Meta-target

bindings: gen-bindings

build: bindings compile-go

# ==============================================================================

# RUN DEMO

# ==============================================================================

run-user-setup: build
	@echo "==> (PHASE 1) Running User Setup..."
	@mkdir -p $(DEPLOYMENTS_DIR)
	./$(GO_BUILD)/user

run-agent: build
	@echo "==> (PHASE 2) Running Agent..."
	./$(GO_BUILD)/agent || true

# ==============================================================================

# CLEANUP

# ==============================================================================

clean:
	@echo "==> Cleaning up build artifacts..."
	@rm -rf $(CONTRACT_BUILD_DIR)
	@rm -fr $(CONTRACTS_DIR)/cache
	@rm -rf $(CONTRACTS_DIR)/lib
	@rm -rf $(BINDINGS_DIR)
	@rm -rf $(DEPLOYMENTS_DIR)
	@rm -rf ${GO_BUILD}