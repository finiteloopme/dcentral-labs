# Makefile for running ABI Assistant examples
# Usage: make <target>

.PHONY: help all rust-examples shell-examples python-examples \
        intent-resolution transaction-building library-usage \
        curl-demo defi-operations intent-shell transaction-tools quick-test \
        gemini-demo gemini-intent clean

# Default target
help:
	@echo "ABI Assistant Examples - Available targets:"
	@echo ""
	@echo "All Examples:"
	@echo "  make all              - Run all examples (Rust, Shell, Python)"
	@echo ""
	@echo "Rust Examples:"
	@echo "  make rust-examples    - Run all Rust examples"
	@echo "  make intent-resolution - Run intent resolution example"
	@echo "  make transaction-building - Run transaction building example"
	@echo "  make library-usage    - Run library usage example"
	@echo ""
	@echo "Shell/cURL Examples:"
	@echo "  make shell-examples   - Run all shell examples"
	@echo "  make curl-demo        - Run basic MCP cURL demo"
	@echo "  make defi-operations  - Run DeFi operations demo"
	@echo "  make intent-shell     - Run intent resolution shell demo"
	@echo "  make transaction-tools - Run transaction tools demo"
	@echo "  make quick-test       - Run quick test script"
	@echo ""
	@echo "Python/Gemini Examples:"
	@echo "  make python-examples  - Run all Python examples"
	@echo "  make gemini-demo      - Run Gemini agent demo"
	@echo "  make gemini-intent    - Run Gemini intent integration"
	@echo ""
	@echo "Utilities:"
	@echo "  make clean            - Clean build artifacts"
	@echo "  make check-deps       - Check required dependencies"
	@echo ""
	@echo "Note: Examples assume MCP service is running on localhost:3000"

# Run all examples
all: rust-examples shell-examples python-examples

# Rust Examples
rust-examples: intent-resolution transaction-building library-usage
	@echo "✅ All Rust examples completed"

intent-resolution:
	@echo "=== Running Intent Resolution Example (Rust) ==="
	@cd .. && cargo run --example intent-resolution

transaction-building:
	@echo "=== Running Transaction Building Example (Rust) ==="
	@cd .. && cargo run --example transaction-building

library-usage:
	@echo "=== Running Library Usage Example (Rust) ==="
	@cd .. && cargo run --example library-usage

# Shell/cURL Examples (assume external MCP service is running)
shell-examples: curl-demo defi-operations intent-shell transaction-tools quick-test
	@echo "✅ All shell examples completed"

curl-demo:
	@echo "=== Running MCP cURL Demo ==="
	@bash curl-client/mcp-curl-demo.sh

defi-operations:
	@echo "=== Running DeFi Operations Demo ==="
	@bash curl-client/defi-operations.sh

intent-shell:
	@echo "=== Running Intent Resolution Shell Demo ==="
	@bash curl-client/intent-resolution.sh

transaction-tools:
	@echo "=== Running Transaction Tools Demo ==="
	@bash curl-client/transaction-tools.sh

quick-test:
	@echo "=== Running Quick Test ==="
	@bash curl-client/quick-test.sh

# Python/Gemini Examples
python-examples: check-python gemini-demo gemini-intent
	@echo "✅ All Python examples completed"

gemini-demo: check-python
	@echo "=== Running Gemini Agent Demo ==="
	@cd gemini-agent && python example.py

gemini-intent: check-python
	@echo "=== Running Gemini Intent Integration ==="
	@cd gemini-agent && python intent-integration.py



# Check Python dependencies
check-python:
	@echo "Checking Python dependencies..."
	@python3 --version > /dev/null 2>&1 || \
		(echo "❌ Python 3 not found" && exit 1)
	@echo "✅ Python 3 found"

# Check all dependencies
check-deps:
	@echo "Checking dependencies..."
	@cargo --version > /dev/null 2>&1 || \
		(echo "❌ Cargo not found. Install Rust: https://rustup.rs" && exit 1)
	@echo "✅ Cargo found"
	@python3 --version > /dev/null 2>&1 || \
		(echo "⚠️  Python 3 not found (needed for Gemini examples)" && exit 0)
	@echo "✅ Python 3 found"
	@curl --version > /dev/null 2>&1 || \
		(echo "❌ curl not found" && exit 1)
	@echo "✅ curl found"
	@jq --version > /dev/null 2>&1 || \
		(echo "⚠️  jq not found (needed for pretty JSON output)" && exit 0)
	@echo "✅ jq found"
	@echo ""
	@echo "✅ All required dependencies are installed"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@cd .. && cargo clean
	@rm -f /tmp/abi-assistant.log
	@echo "✅ Cleaned"

# Individual example descriptions
.PHONY: describe-intent-resolution describe-transaction-building describe-library-usage

describe-intent-resolution:
	@echo "Intent Resolution Example:"
	@echo "  Demonstrates natural language to smart contract call conversion"
	@echo "  Uses both local pattern matching and optional Gemini AI"
	@echo "  Shows caching and hybrid resolution strategies"

describe-transaction-building:
	@echo "Transaction Building Example:"
	@echo "  Shows complete transaction lifecycle"
	@echo "  Demonstrates ABI encoding/decoding"
	@echo "  Exports transactions in multiple wallet formats"

describe-library-usage:
	@echo "Library Usage Example:"
	@echo "  Basic usage of ABI Assistant as a Rust library"
	@echo "  Shows how to integrate into your own projects"

# Quick start targets
.PHONY: quickstart demo

quickstart: check-deps
	@echo "=== ABI Assistant Quick Start ==="
	@echo "Note: Assuming MCP service is running on localhost:3000"
	@echo ""
	@make quick-test
	@echo ""
	@echo "✅ Quick start complete!"
	@echo "Try other examples:"
	@echo "  make intent-resolution"
	@echo "  make transaction-building"
	@echo "  make curl-demo"

demo:
	@echo "=== Running Full Demo ==="
	@echo "Note: Assuming MCP service is running on localhost:3000"
	@echo ""
	@make intent-resolution
	@echo ""
	@make transaction-building
	@echo ""
	@make transaction-tools
	@echo ""
	@echo "✅ Demo complete!"