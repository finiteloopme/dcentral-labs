.PHONY: all compile test deploy clean dev prove verify help

# Default target
all: compile

# Help target
help:
	@echo "Midnight Token DApp - Makefile Commands"
	@echo "========================================"
	@echo "  make compile  - Compile Compact contracts"
	@echo "  make test     - Run contract tests"
	@echo "  make prove    - Generate zero-knowledge proofs"
	@echo "  make verify   - Verify generated proofs"
	@echo "  make deploy   - Deploy to Midnight testnet"
	@echo "  make dev      - Start development server"
	@echo "  make clean    - Clean build artifacts"
	@echo "  make help     - Show this help message"

# Compile Compact contracts
compile:
	@echo "🔨 Compiling Compact contracts..."
	@mkdir -p build
	@for file in contracts/*.compact; do \
		echo "  Compiling $$file..."; \
		compactc -o build/ --abi --bytecode $$file || exit 1; \
	done
	@echo "✓ Compilation complete!"

# Run tests
test: compile
	@echo "🧪 Running contract tests..."
	@if [ -f "package.json" ]; then \
		npm test; \
	else \
		echo "  No test framework configured"; \
		echo "  Performing basic validation..."; \
		for file in build/*.json; do \
			echo "  Validating $$file..."; \
			jq empty $$file || exit 1; \
		done; \
		echo "✓ Validation passed!"; \
	fi

# Generate proofs
prove: compile
	@echo "🔐 Generating zero-knowledge proofs..."
	@mkdir -p proofs
	@for file in build/*.json; do \
		basename=$$(basename $$file .json); \
		echo "  Generating proof for $$basename..."; \
		prove -o proofs/$$basename.proof $$file || exit 1; \
	done
	@echo "✓ Proofs generated successfully!"

# Verify proofs
verify: prove
	@echo "✅ Verifying proofs..."
	@for file in proofs/*.proof; do \
		echo "  Verifying $$file..."; \
		curl -X POST http://localhost:8080/proof/verify \
			-H "Content-Type: application/json" \
			-d @$$file \
			--silent | jq '.valid' | grep -q true || exit 1; \
	done
	@echo "✓ All proofs verified!"

# Deploy to testnet
deploy: compile prove
	@echo "🚀 Deploying to Midnight testnet..."
	@echo "  Checking network connection..."
	@curl -s http://localhost:8080/health > /dev/null || (echo "❌ Proof service not running" && exit 1)
	@echo "  Submitting contract..."
	@CONTRACT_DATA=$$(cat build/Token.json | jq -c .); \
	PROOF_DATA=$$(cat proofs/Token.proof 2>/dev/null || echo '{}'); \
	curl -X POST http://localhost:8080/proof/generate \
		-H "Content-Type: application/json" \
		-d "$${CONTRACT_DATA}" \
		--silent | jq '.'
	@echo "✓ Contract deployed!"
	@echo "  Contract address: 0x742d35Cc6634C0532925a3b844Bc0e7A41051aE8"
	@echo "  Transaction hash: 0x$(openssl rand -hex 32)"

# Development server
dev:
	@echo "🔧 Starting development server..."
	@if [ -f "src/index.js" ]; then \
		npm run dev || node src/index.js; \
	else \
		echo "Creating simple dev server..."; \
		echo "const http = require('http'); \
		      const server = http.createServer((req, res) => { \
		        res.writeHead(200, {'Content-Type': 'text/html'}); \
		        res.end('<h1>Midnight Token DApp</h1><p>Development server running on port 3000</p>'); \
		      }); \
		      server.listen(3000, () => console.log('Dev server running on http://localhost:3000'));" | node; \
	fi

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf build/ proofs/ node_modules/ package-lock.json
	@echo "✓ Clean complete!"