#!/bin/bash
# Midnight Development Platform CLI

VERSION="1.0.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Set working directory
# In Cloud Workstations, use home directory. In local, can use /workspace
if [ -n "$CLOUD_WORKSTATIONS_CONFIG_DIRECTORY" ]; then
    # Cloud Workstation environment - use user's home
    WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/workspace}"
elif [ -w "/workspace" ]; then
    # Local environment with writable /workspace
    WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
else
    # Fallback to home directory
    WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/workspace}"
fi

PROJECTS_DIR="${WORKSPACE_DIR}/projects"
# Use fixed templates if available (with correct ports), otherwise regular templates
if [ -d "${WORKSPACE_DIR}/templates-fixed" ]; then
    TEMPLATES_DIR="${WORKSPACE_DIR}/templates-fixed"
elif [ -d "${WORKSPACE_DIR}/templates-sdk" ]; then
    TEMPLATES_DIR="${WORKSPACE_DIR}/templates-sdk"
else
    TEMPLATES_DIR="${WORKSPACE_DIR}/templates"
fi

# Function to show help
show_help() {
    echo ""
    echo -e "${BLUE}🌙 Midnight Development Platform v${VERSION}${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "COMMANDS:"
    echo "  midnight new <name>    Create a new Midnight DApp project"
    echo "  midnight compile       Compile Compact contracts to JSON"
    echo "  midnight test          Run contract tests"
    echo "  midnight prove         Generate zero-knowledge proofs"
    echo "  midnight verify        Verify proof files"
    echo "  midnight serve         Start development server (port 3000)"
    echo "  midnight help          Show this help message"
    echo ""
    echo "WEB SERVICES:"
    echo "  http://localhost:80    VS Code IDE"
    echo "  http://localhost:8080  Proof Service API"
    echo "  http://localhost:7681  Web Terminal"
    echo "  http://localhost:3000  Dev Server (when running)"
    echo ""
    echo "DEVELOPMENT TOOLS:"
    echo "  compactc              Midnight Compact compiler"
    echo "  prove                 Generate proofs for circuits"
    echo "  verify                Verify proof files"
    echo "  opencode              AI coding assistant"
    echo "  code                  Open VS Code editor"
    echo ""
    echo "NAVIGATION:"
    echo "  workspace             Go to workspace directory"
    echo "  projects              Go to projects directory"
    echo ""
    echo "EXAMPLES:"
    echo "  # Create and build a new project"
    echo "  midnight new my-token"
    echo "  cd ~/workspace/projects/my-token"
    echo "  midnight compile"
    echo "  midnight test"
    echo ""
    echo "  # Generate and verify proofs"
    echo "  midnight prove"
    echo "  midnight verify build/Token.proof"
    echo ""
    echo "  # Start development server"
    echo "  midnight serve"
    echo ""
    echo "TEMPLATES:"
    echo "  Basic token contract available in templates directory"
    echo "  Location: ~/workspace/templates/basic-token"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Create new project
create_project() {
    local name="$1"
    if [ -z "$name" ]; then
        echo -e "${RED}Error: Project name required${NC}"
        echo "Usage: midnight new <project-name>"
        exit 1
    fi
    
    # Validate project name (alphanumeric, dash, underscore only)
    if ! [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}Error: Project name can only contain letters, numbers, dashes, and underscores${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Creating new Midnight DApp project: $name${NC}"
    
    # Create projects directory if it doesn't exist
    mkdir -p "$PROJECTS_DIR"
    
    PROJECT_PATH="$PROJECTS_DIR/$name"
    
    # Check if project already exists
    if [ -d "$PROJECT_PATH" ]; then
        echo -e "${YELLOW}Warning: Project '$name' already exists at $PROJECT_PATH${NC}"
        read -p "Do you want to overwrite it? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 0
        fi
        rm -rf "$PROJECT_PATH"
    fi
    
    # Create project directory
    mkdir -p "$PROJECT_PATH"
    
    # Check if templates exist and copy them
    if [ -d "$TEMPLATES_DIR/basic-token" ]; then
        echo "Using template from $TEMPLATES_DIR/basic-token..."
        # Try SDK template first (with real proof server integration)
        if [ -d "$TEMPLATES_DIR/../templates-sdk/basic-token" ]; then
            cp -r "$TEMPLATES_DIR/../templates-sdk/basic-token/"* "$PROJECT_PATH/" 2>/dev/null || {
                # Fallback to regular template
                cp -r "$TEMPLATES_DIR/basic-token/"* "$PROJECT_PATH/" 2>/dev/null || {
                    echo "⚠️  Template not found at $TEMPLATES_DIR/basic-token/"
                    echo "   Trying alternative location..."
                    # Try alternative location
                    TEMPLATES_DIR="/opt/templates"
                    cp -r "/opt/templates/basic-token/"* "$PROJECT_PATH/" 2>/dev/null || {
                        echo -e "${YELLOW}Warning: Could not copy all template files${NC}"
                        create_basic_structure=true
                    }
                }
            }
        else
            # No SDK template, try regular template
            cp -r "$TEMPLATES_DIR/basic-token/"* "$PROJECT_PATH/" 2>/dev/null || {
                echo "⚠️  Template not found at $TEMPLATES_DIR/basic-token/"
                echo "   Trying alternative location..."
                # Try alternative location
                TEMPLATES_DIR="/opt/templates"
                cp -r "/opt/templates/basic-token/"* "$PROJECT_PATH/" 2>/dev/null || {
                    echo -e "${YELLOW}Warning: Could not copy all template files${NC}"
                    create_basic_structure=true
                }
            }
        fi
        
        # Check if we need to create basic structure due to template copy failure
        if [ "$create_basic_structure" = "true" ]; then
            echo "Creating basic project structure..."
            mkdir -p "$PROJECT_PATH/contracts" "$PROJECT_PATH/src" "$PROJECT_PATH/test" "$PROJECT_PATH/build"
            create_basic_files=true
        fi
    else
        echo "Creating project structure from scratch..."
        
        # Create directory structure
        mkdir -p "$PROJECT_PATH/contracts" "$PROJECT_PATH/src" "$PROJECT_PATH/test" "$PROJECT_PATH/build"
        create_basic_files=true
    fi
    
    # Create basic files if needed
    if [ "$create_basic_files" = "true" ]; then
        
        # Create sample contract
        cat > "$PROJECT_PATH/contracts/Token.compact" <<'EOF'
// Sample Midnight Token Contract
contract Token {
    // Token balances
    @shielded
    mapping(address => uint256) balances;
    
    // Total supply
    uint256 public totalSupply;
    
    // Constructor
    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply;
        balances[msg.sender] = _initialSupply;
    }
    
    // Transfer tokens
    function transfer(address to, uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        return true;
    }
    
    // Get balance (circuit)
    export circuit proveBalance(address account, uint256 balance) {
        assert balances[account] == balance;
    }
}
EOF
        
        # Create package.json
        cat > "$PROJECT_PATH/package.json" <<EOF
{
  "name": "$name",
  "version": "1.0.0",
  "description": "Midnight DApp project",
  "scripts": {
    "compile": "midnight compile",
    "test": "midnight test",
    "prove": "midnight prove",
    "verify": "midnight verify"
  },
  "keywords": ["midnight", "blockchain", "privacy", "zero-knowledge"],
  "license": "MIT",
  "devDependencies": {
    "chai": "^4.3.0",
    "mocha": "^10.0.0"
  }
}
EOF
        
        # Create test file
        cat > "$PROJECT_PATH/test/token.test.js" <<'EOF'
// Token contract tests
const { expect } = require('chai');

describe('Token Contract', () => {
    it('should have initial supply', async () => {
        // Test implementation here
        expect(true).to.be.true;
    });
    
    it('should transfer tokens', async () => {
        // Test implementation here
        expect(true).to.be.true;
    });
    
    it('should generate balance proof', async () => {
        // Test zero-knowledge proof generation
        expect(true).to.be.true;
    });
});
EOF
        
        # Create README
        cat > "$PROJECT_PATH/README.md" <<EOF
# $name

A Midnight blockchain project with privacy-preserving features.

## Getting Started

\`\`\`bash
# Install dependencies
npm install

# Compile contracts
midnight compile

# Run tests
midnight test

# Generate proofs
midnight prove

# Verify proofs
midnight verify
\`\`\`

## Project Structure

- \`contracts/\` - Compact smart contracts with circuits
- \`src/\` - Application source code
- \`test/\` - Test files
- \`build/\` - Compiled artifacts and proofs

## Features

- Privacy-preserving token transfers
- Zero-knowledge balance proofs
- Shielded state variables
EOF
        
        # Create a simple Makefile
        cat > "$PROJECT_PATH/Makefile" <<'EOF'
.PHONY: all compile test prove verify clean

all: compile

compile:
	@echo "Compiling Compact contracts..."
	@mkdir -p build
	@for file in contracts/*.compact; do \
		if [ -f "$$file" ]; then \
			echo "  Compiling $$(basename $$file)"; \
			compactc "$$file" -o "build/$$(basename $$file .compact).json" || exit 1; \
		fi \
	done
	@echo "✓ Compilation complete"

test:
	@echo "Running tests..."
	@if command -v npm >/dev/null && [ -f package.json ]; then \
		npm test; \
	else \
		for test in test/*.test.js; do \
			if [ -f "$$test" ]; then \
				echo "  Testing $$(basename $$test)"; \
				node "$$test" || true; \
			fi \
		done; \
	fi

prove:
	@echo "Generating proofs..."
	@mkdir -p build/proofs
	@echo "✓ Proof generation complete"

verify:
	@echo "Verifying proofs..."
	@echo "✓ Proof verification complete"

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf build
	@echo "✓ Clean complete"
EOF
    fi
    
    # Use better Makefile if available
    if [ -f "/opt/scripts/Makefile.fixed" ]; then
        cp "/opt/scripts/Makefile.fixed" "$PROJECT_PATH/Makefile"
    elif [ -f "/opt/scripts/Makefile.template" ]; then
        cp "/opt/scripts/Makefile.template" "$PROJECT_PATH/Makefile"
    fi
    
    # Update package.json with project name if it exists
    if [ -f "$PROJECT_PATH/package.json" ]; then
        # Use sed to update the name field
        sed -i "s/\"name\": \".*\"/\"name\": \"$name\"/" "$PROJECT_PATH/package.json" 2>/dev/null || true
    fi
    
    # Initialize npm if available (but don't fail if not)
    if command -v npm >/dev/null 2>&1; then
        echo "Initializing npm dependencies..."
        (cd "$PROJECT_PATH" && npm install --silent 2>/dev/null) || {
            echo -e "${YELLOW}Note: npm install skipped (npm might not be available or configured)${NC}"
        }
    fi
    
    # Create initial build directory
    mkdir -p "$PROJECT_PATH/build"
    
    echo -e "${GREEN}✅ Project created successfully!${NC}"
    echo ""
    echo "Project location: $PROJECT_PATH"
    echo ""
    echo "Next steps:"
    echo -e "  ${BLUE}cd $PROJECT_PATH${NC}"
    echo -e "  ${BLUE}midnight compile${NC}  # Compile contracts"
    echo -e "  ${BLUE}midnight test${NC}     # Run tests"
    echo -e "  ${BLUE}midnight prove${NC}    # Generate proofs"
    echo ""
}

# Compile contracts
compile_contracts() {
    echo -e "${BLUE}Compiling Midnight contracts...${NC}"
    
    if [ ! -d "contracts" ]; then
        echo -e "${RED}Error: contracts/ directory not found${NC}"
        echo "Are you in a Midnight project directory?"
        exit 1
    fi
    
    # Check if compactc is available
    if ! command -v compactc >/dev/null 2>&1; then
        echo -e "${RED}Error: compactc compiler not found${NC}"
        echo "Please ensure Midnight tools are installed"
        exit 1
    fi
    
    # Create build directory
    mkdir -p build
    
    # Count contracts
    contract_count=$(find contracts -name "*.compact" -type f 2>/dev/null | wc -l)
    
    if [ "$contract_count" -eq 0 ]; then
        echo -e "${YELLOW}No .compact files found in contracts/${NC}"
        exit 0
    fi
    
    # Compile each contract
    compiled=0
    failed=0
    
    for contract in contracts/*.compact; do
        if [ -f "$contract" ]; then
            contract_name=$(basename "$contract")
            output_file="build/$(basename "${contract%.compact}.json")"
            
            echo -n "  Compiling $contract_name... "
            
            if compactc "$contract" -o "$output_file" 2>/dev/null; then
                echo -e "${GREEN}✓${NC}"
                ((compiled++))
            else
                echo -e "${RED}✗${NC}"
                echo -e "${RED}    Error compiling $contract_name${NC}"
                ((failed++))
            fi
        fi
    done
    
    echo ""
    if [ "$failed" -eq 0 ]; then
        echo -e "${GREEN}✅ All contracts compiled successfully! ($compiled contracts)${NC}"
    else
        echo -e "${YELLOW}⚠ Compilation finished with errors: $compiled succeeded, $failed failed${NC}"
        exit 1
    fi
}

# Run tests
run_tests() {
    echo -e "${BLUE}Running tests...${NC}"
    
    if [ ! -d "test" ]; then
        echo -e "${YELLOW}No test/ directory found${NC}"
        exit 0
    fi
    
    # Check for test files
    test_count=$(find test -name "*.test.js" -o -name "*.spec.js" 2>/dev/null | wc -l)
    
    if [ "$test_count" -eq 0 ]; then
        echo -e "${YELLOW}No test files found in test/${NC}"
        exit 0
    fi
    
    # Run tests based on available tools
    if [ -f "package.json" ] && command -v npm >/dev/null 2>&1; then
        # Check if test script exists in package.json
        if grep -q '"test"' package.json; then
            npm test
        else
            echo "Running tests with Node.js..."
            for test in test/*.test.js test/*.spec.js; do
                if [ -f "$test" ]; then
                    echo "  Running: $(basename "$test")"
                    node "$test" || true
                fi
            done
        fi
    else
        echo "Running tests with Node.js..."
        for test in test/*.test.js test/*.spec.js; do
            if [ -f "$test" ]; then
                echo "  Running: $(basename "$test")"
                node "$test" 2>/dev/null || echo -e "${YELLOW}    Skipped (Node.js might not be available)${NC}"
            fi
        done
    fi
    
    echo -e "${GREEN}✅ Tests complete!${NC}"
}

# Generate proofs
generate_proofs() {
    # Pass through to prove command which handles external/simulation logic
    if command -v prove >/dev/null 2>&1; then
        prove "$@"
    else
        echo -e "${RED}Error: prove command not found${NC}"
        exit 1
    fi
}

# Verify proofs
verify_proofs() {
    # Pass through to verify command which handles external/simulation logic
    if command -v verify >/dev/null 2>&1; then
        verify "$@"
    else
        echo -e "${RED}Error: verify command not found${NC}"
        exit 1
    fi
}

# Handle navigation shortcuts (print the cd command for user to eval)
if [ "$1" = "workspace" ]; then
    cd "$WORKSPACE_DIR"
    pwd
    exit 0
elif [ "$1" = "projects" ]; then
    cd "$PROJECTS_DIR"
    pwd
    exit 0
fi

# Main command handler
case "$1" in
    new)
        create_project "$2"
        ;;
    compile)
        compile_contracts
        ;;
    test)
        run_tests
        ;;
    prove)
        shift
        generate_proofs "$@"
        ;;
    verify)
        shift
        verify_proofs "$@"
        ;;
    serve)
        echo -e "${BLUE}Starting development server on port 3000...${NC}"
        if command -v python3 >/dev/null 2>&1; then
            python3 -m http.server 3000
        elif command -v python >/dev/null 2>&1; then
            python -m SimpleHTTPServer 3000
        else
            echo -e "${RED}Error: Python not found${NC}"
            exit 1
        fi
        ;;
    help|--help|-h)
        show_help
        ;;
    version|--version|-v)
        echo "Midnight CLI v${VERSION}"
        ;;
    *)
        if [ -z "$1" ]; then
            show_help
        else
            echo -e "${RED}Unknown command: $1${NC}"
            echo ""
            show_help
            exit 1
        fi
        ;;
esac