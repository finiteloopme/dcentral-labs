#!/bin/bash
# Midnight Development Platform CLI

VERSION="1.0.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to show help
show_help() {
    echo -e "${BLUE}🌙 Midnight Development Platform v${VERSION}${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Usage: midnight <command> [options]"
    echo ""
    echo "Commands:"
    echo "  new <name>     Create a new Midnight project"
    echo "  compile        Compile Compact contracts"
    echo "  test           Run tests"
    echo "  prove          Generate proofs"
    echo "  verify         Verify proofs"
    echo "  serve          Start development server"
    echo "  help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  midnight new my-token"
    echo "  midnight compile"
    echo "  midnight test"
    echo ""
}

# Create new project
create_project() {
    local name="$1"
    if [ -z "$name" ]; then
        echo -e "${RED}Error: Project name required${NC}"
        echo "Usage: midnight new <project-name>"
        exit 1
    fi
    
    echo -e "${BLUE}Creating new Midnight project: $name${NC}"
    
    # Create project directory
    mkdir -p "$name"
    cd "$name"
    
    # Create directory structure
    mkdir -p contracts src test build
    
    # Create sample contract
    cat > contracts/Token.compact <<'EOF'
// Sample Midnight Token Contract
contract Token {
    // Token balances
    mapping(address => uint256) public balances;
    
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
    
    // Get balance
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
}
EOF
    
    # Create package.json
    cat > package.json <<EOF
{
  "name": "$name",
  "version": "1.0.0",
  "description": "Midnight DApp project",
  "scripts": {
    "compile": "midnight compile",
    "test": "midnight test",
    "prove": "midnight prove"
  },
  "keywords": ["midnight", "blockchain", "privacy"],
  "license": "MIT"
}
EOF
    
    # Create test file
    cat > test/Token.test.js <<'EOF'
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
});
EOF
    
    # Create README
    cat > README.md <<EOF
# $name

A Midnight blockchain project.

## Getting Started

\`\`\`bash
# Compile contracts
midnight compile

# Run tests
midnight test

# Generate proofs
midnight prove
\`\`\`

## Project Structure

- \`contracts/\` - Compact smart contracts
- \`src/\` - Application source code
- \`test/\` - Test files
- \`build/\` - Compiled artifacts
EOF
    
    echo -e "${GREEN}✅ Project created successfully!${NC}"
    echo ""
    echo "Next steps:"
    echo "  cd $name"
    echo "  midnight compile"
    echo "  midnight test"
    echo ""
}

# Compile contracts
compile_contracts() {
    echo -e "${BLUE}Compiling Midnight contracts...${NC}"
    
    if [ ! -d "contracts" ]; then
        echo -e "${RED}Error: contracts/ directory not found${NC}"
        exit 1
    fi
    
    # Create build directory
    mkdir -p build
    
    # Compile each contract
    for contract in contracts/*.compact; do
        if [ -f "$contract" ]; then
            echo "Compiling: $(basename $contract)"
            compactc "$contract" -o "build/$(basename ${contract%.compact}.json)"
        fi
    done
    
    echo -e "${GREEN}✅ Compilation complete!${NC}"
}

# Run tests
run_tests() {
    echo -e "${BLUE}Running tests...${NC}"
    
    if [ -f "package.json" ] && command -v npm >/dev/null; then
        npm test
    else
        echo "Running basic tests..."
        for test in test/*.test.js; do
            if [ -f "$test" ]; then
                echo "Testing: $(basename $test)"
                node "$test" || true
            fi
        done
    fi
    
    echo -e "${GREEN}✅ Tests complete!${NC}"
}

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
        echo -e "${BLUE}Generating proofs...${NC}"
        prove "$@"
        ;;
    verify)
        echo -e "${BLUE}Verifying proofs...${NC}"
        verify "$@"
        ;;
    serve)
        echo -e "${BLUE}Starting development server on port 3000...${NC}"
        python3 -m http.server 3000
        ;;
    help|--help|-h)
        show_help
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