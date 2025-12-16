#!/bin/bash
# Midnight Vibe Platform - Setup Script
# Sets up Midnight development environment

set -e

echo "🌙 Setting up Midnight Vibe Platform..."

# This script runs as root during startup, need to setup for actual users
# Create user-local directories for ubuntu user (primary user in Cloud Workstation)
mkdir -p /home/ubuntu/midnight-dev/logs
mkdir -p /home/ubuntu/midnight-dev/data
mkdir -p /home/ubuntu/midnight-dev/config
mkdir -p /home/ubuntu/midnight-dev/bin

# Copy Midnight configuration files to user directory
cp /tmp/midnight-config/* /home/ubuntu/midnight-dev/config/ 2>/dev/null || true

# Also create for user directory if it exists (fallback)
if [ -d "/home/user" ]; then
    mkdir -p /home/user/midnight-dev/logs
    mkdir -p /home/user/midnight-dev/data
    mkdir -p /home/user/midnight-dev/config
    mkdir -p /home/user/midnight-dev/bin
    cp /tmp/midnight-config/* /home/user/midnight-dev/config/ 2>/dev/null || true
fi

# OpenCode configuration is handled by 230_opencode-user-config.sh (runs earlier)

# Set up npm-based Midnight development environment
echo "🔧 Setting up npm-based Midnight development environment..."

# Set up for current user (whoever is running this)
CURRENT_USER=$(whoami)
CURRENT_HOME=$(eval echo "~$CURRENT_USER")

echo "🔧 Setting up Midnight development for user: $CURRENT_USER"

# Create Midnight development directories
mkdir -p "$CURRENT_HOME/midnight-dev/projects"
mkdir -p "$CURRENT_HOME/midnight-dev/templates"
mkdir -p "$CURRENT_HOME/midnight-dev/logs"
mkdir -p "$CURRENT_HOME/midnight-dev/data"
mkdir -p "$CURRENT_HOME/midnight-dev/config"
mkdir -p "$CURRENT_HOME/midnight-dev/bin"

# Copy Midnight configuration files
cp /tmp/midnight-config/* "$CURRENT_HOME/midnight-dev/config/" 2>/dev/null || true

# Set up npm global configuration for Midnight packages
if [ ! -f "$CURRENT_HOME/.npmrc" ]; then
    echo "🔧 Creating npm configuration for Midnight development..."
    cat > "$CURRENT_HOME/.npmrc" << 'EOF'
# Midnight Development Configuration
@midnight-network:registry=https://registry.npmjs.org/
# Enable npm scripts for Midnight contracts
script-shell=/bin/bash
EOF
    chown "$CURRENT_USER:$CURRENT_USER" "$CURRENT_HOME/.npmrc" 2>/dev/null || true
    chmod 644 "$CURRENT_HOME/.npmrc"
fi

# Create Midnight project template with working compilation workflow
mkdir -p "$CURRENT_HOME/midnight-dev/templates/compact-contract/src/contracts"
cat > "$CURRENT_HOME/midnight-dev/templates/compact-contract/package.json" << 'EOF'
{
  "name": "midnight-contract-template",
  "version": "1.0.0",
  "description": "Midnight Smart Contract Template",
  "main": "index.js",
  "scripts": {
    "compile": "mkdir -p dist/contracts && node scripts/compile-contracts.js",
    "build": "npm run compile",
    "clean": "rm -rf dist",
    "dev": "npm run compile"
  },
  "devDependencies": {},
  "keywords": ["midnight", "blockchain", "smart-contract"],
  "author": "Midnight Developer",
  "license": "MIT"
}
EOF

# Create compilation script that handles metadata requirements
mkdir -p "$CURRENT_HOME/midnight-dev/templates/compact-contract/scripts"
cat > "$CURRENT_HOME/midnight-dev/templates/compact-contract/scripts/compile-contracts.js" << 'EOF'
#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const contractsDir = path.join(__dirname, '../src/contracts');
const distDir = path.join(__dirname, '../dist/contracts');

// Ensure output directory exists
if (!fs.existsSync(distDir)) {
  fs.mkdirSync(distDir, { recursive: true });
}

// Get all .compact files
const contractFiles = fs.readdirSync(contractsDir).filter(file => file.endsWith('.compact'));

if (contractFiles.length === 0) {
  console.log('⚠️  No .compact files found in src/contracts/');
  process.exit(0);
}

console.log(`🔨 Compiling ${contractFiles.length} contract(s)...`);

contractFiles.forEach(file => {
  const contractPath = path.join(contractsDir, file);
  const contractName = path.basename(file, '.compact');
  const contractOutputDir = path.join(distDir, contractName);
  const contractMetadataDir = path.join(distDir, contractName + '.compact');
  
  console.log(`\n📄 Compiling ${file}...`);
  
  // Create output directory for this contract (without .compact extension)
  if (!fs.existsSync(contractOutputDir)) {
    fs.mkdirSync(contractOutputDir, { recursive: true });
  }
  
  // Create metadata directory with .compact extension where compiler expects it
  if (!fs.existsSync(contractMetadataDir)) {
    fs.mkdirSync(contractMetadataDir, { recursive: true });
  }
  
  // Create the compiler directory and contract-info.json that compactc expects
  const compilerDir = path.join(contractMetadataDir, 'compiler');
  if (!fs.existsSync(compilerDir)) {
    fs.mkdirSync(compilerDir, { recursive: true });
  }
  
  // Create contract-info.json with correct format from analysis
  const contractInfo = {
    name: contractName,
    version: "1.0.0",
    compiler: "0.26.0",
    contracts: [contractName],
    circuits: []
  };
  fs.writeFileSync(
    path.join(compilerDir, 'contract-info.json'),
    JSON.stringify(contractInfo, null, 2)
  );
  
  try {
    // Compile using Compact CLI with timeout to prevent hanging
    execSync(`compact compile "${contractPath}" "${contractOutputDir}"`, {
      stdio: 'inherit',
      cwd: __dirname + '/..',
      timeout: 60000 // 60 second timeout for CLI
    });
    
    console.log(`✅ ${file} compiled successfully`);
    
    // List generated files
    const generatedFiles = fs.readdirSync(contractOutputDir);
    console.log(`📁 Generated files: ${generatedFiles.join(', ')}`);
    
  } catch (error) {
    console.error(`❌ Failed to compile ${file}:`, error.message);
    if (error.signal === 'SIGTERM') {
      console.error(`⏱️  Compilation timed out - this may indicate a compiler issue`);
    }
    process.exit(1);
  }
});

console.log('\n✅ All contracts compiled successfully!');
EOF

chmod +x "$CURRENT_HOME/midnight-dev/templates/compact-contract/scripts/compile-contracts.js"

# Create example contract with correct Compact syntax
cat > "$CURRENT_HOME/midnight-dev/templates/compact-contract/src/contracts/Example.compact" << 'EOF'
// Example Midnight Smart Contract
// This is a template for creating Midnight contracts
// Note: Use 'circuit' instead of 'function', with explicit types and semicolons

contract Example {
  circuit main(x : Field) : Field;
}
EOF

# Create README for template
cat > "$CURRENT_HOME/midnight-dev/templates/compact-contract/README.md" << 'EOF'
# Midnight Smart Contract Template

## Overview
This is a template for developing Midnight smart contracts using npm-based workflow with automatic metadata handling.

## Prerequisites
- Node.js 20+
- Midnight Compact compiler (installed in container)

## Development Workflow

### 1. Install Dependencies
\`\`\`bash
npm install
\`\`\`

### 2. Write Contracts
Place your `.compact` contract files in `src/contracts/`

### 3. Compile Contracts
\`\`\`bash
npm run compile
\`\`\`

### 4. Build Project
\`\`\`bash
npm run build
\`\`\`

## Project Structure
\`\`\`
src/contracts/          # Compact contract source files
scripts/compile-contracts.js  # Compilation script with metadata handling
dist/contracts/         # Compiled contract outputs
package.json            # NPM configuration
README.md              # This file
\`\`\`

## Compilation Features
- **Automatic Metadata Handling**: Creates required contract-info.json files
- **Directory Structure Management**: Sets up proper compiler directory structure
- **Error Handling**: Provides clear error messages and debugging info
- **Multiple Contract Support**: Compiles all .compact files in src/contracts/
- **TypeScript Generation**: Generates TypeScript equivalents of contracts
- **ZK Circuit Support**: Creates zero-knowledge circuit files (skipped for faster development)

## Best Practices
- Use npm scripts for compilation (not direct compact/compactc calls)
- Follow Midnight documentation for contract syntax
- Use proper project structure with separate src/dist directories
- Test contracts in development environment before deployment
- The compilation script handles all Compact compiler metadata requirements automatically

## Troubleshooting
If compilation fails:
1. Check that your .compact files have valid syntax
2. Ensure Node.js is available (node scripts/compile-contracts.js)
3. Verify compactc.bin is in your PATH
4. Check that ~/.compact/config.toml exists and points to compiler version 0.25.0
EOF

# Set proper ownership
chown -R "$CURRENT_USER:$CURRENT_USER" "$CURRENT_HOME/midnight-dev" 2>/dev/null || true
chmod -R 755 "$CURRENT_HOME/midnight-dev" 2>/dev/null || true

# Also set up for other common users in Cloud Workstation environments
for USER_HOME in "/home/ubuntu" "/home/user"; do
    if [ "$CURRENT_USER" != "$(basename "$USER_HOME")" ] && [ -d "$USER_HOME" ]; then
        USERNAME=$(basename "$USER_HOME")
        echo "🔧 Also setting up Midnight development for user: $USERNAME"
        
        # Create development directories
        mkdir -p "$USER_HOME/midnight-dev/projects"
        mkdir -p "$USER_HOME/midnight-dev/templates"
        mkdir -p "$USER_HOME/midnight-dev/logs"
        mkdir -p "$USER_HOME/midnight-dev/data"
        mkdir -p "$USER_HOME/midnight-dev/config"
        mkdir -p "$USER_HOME/midnight-dev/bin"
        
        # Copy configuration
        cp /tmp/midnight-config/* "$USER_HOME/midnight-dev/config/" 2>/dev/null || true
        
        # Copy template
        cp -r "$CURRENT_HOME/midnight-dev/templates" "$USER_HOME/midnight-dev/"
        
        # Set up npm configuration
        if [ ! -f "$USER_HOME/.npmrc" ]; then
            cat > "$USER_HOME/.npmrc" << 'EOF'
# Midnight Development Configuration
@midnight-network:registry=https://registry.npmjs.org/
# Enable npm scripts for Midnight contracts
script-shell=/bin/bash
EOF
        fi
        
        # Set proper ownership
        chown -R "$USERNAME:$USERNAME" "$USER_HOME/midnight-dev" 2>/dev/null || true
        chown "$USERNAME:$USERNAME" "$USER_HOME/.npmrc" 2>/dev/null || true
        chmod -R 755 "$USER_HOME/midnight-dev" 2>/dev/null || true
        chmod 644 "$USER_HOME/.npmrc" 2>/dev/null || true
        # CRITICAL: Fix home directory permissions so user can write to it
        chmod 755 "$USER_HOME" 2>/dev/null || true
    fi
done

# Create a runtime script to ensure npm-based Midnight development for any user
sudo tee /usr/local/bin/ensure-midnight-dev.sh > /dev/null << 'EOF'
#!/bin/bash
# Ensure npm-based Midnight development environment for current user

USER_HOME="$HOME"
MIDNIGHT_DEV_DIR="$USER_HOME/midnight-dev"
NPM_CONFIG="$USER_HOME/.npmrc"
COMPACT_DIR="$USER_HOME/.compact"
COMPACT_CONFIG="$COMPACT_DIR/config.toml"

# Create compact configuration if it doesn't exist
if [ ! -f "$COMPACT_CONFIG" ]; then
    echo "🔧 Setting up compact config for Midnight development: $(whoami)"
    mkdir -p "$COMPACT_DIR"
    cat > "$COMPACT_CONFIG" << 'COMPACTCONFIG'
[compiler]
default = "0.25.0"
COMPACTCONFIG
    chmod 644 "$COMPACT_CONFIG"
    echo "✅ Compact configuration created at $COMPACT_CONFIG"
    
    # Copy pre-downloaded compiler from system location if available
    if [ -d "/usr/local/share/compact/versions/0.25.0" ]; then
        echo "🔧 Copying pre-downloaded compiler for user: $(whoami)"
        mkdir -p "$COMPACT_DIR/versions"
        cp -r "/usr/local/share/compact/versions/0.25.0" "$COMPACT_DIR/versions/"
        chmod -R 755 "$COMPACT_DIR/versions" 2>/dev/null || true
    elif [ -d "/root/.compact/versions/0.25.0" ]; then
        echo "🔧 Copying compiler from root location for user: $(whoami)"
        mkdir -p "$COMPACT_DIR/versions"
        cp -r "/root/.compact/versions/0.25.0" "$COMPACT_DIR/versions/"
        chmod -R 755 "$COMPACT_DIR/versions" 2>/dev/null || true
    fi
fi

# Create npm configuration if it doesn't exist
if [ ! -f "$NPM_CONFIG" ]; then
    echo "🔧 Setting up npm configuration for Midnight development: $(whoami)"
    cat > "$NPM_CONFIG" << 'NPMRC'
# Midnight Development Configuration
@midnight-network:registry=https://registry.npmjs.org/
# Enable npm scripts for Midnight contracts
script-shell=/bin/bash
NPMRC
    chmod 644 "$NPM_CONFIG"
    echo "✅ npm configuration created at $NPM_CONFIG"
fi

# Ensure Midnight development directories exist
if [ ! -d "$MIDNIGHT_DEV_DIR" ]; then
    echo "🔧 Creating Midnight development directories: $(whoami)"
    mkdir -p "$MIDNIGHT_DEV_DIR/projects"
    mkdir -p "$MIDNIGHT_DEV_DIR/templates"
    mkdir -p "$MIDNIGHT_DEV_DIR/logs"
    mkdir -p "$MIDNIGHT_DEV_DIR/data"
    mkdir -p "$MIDNIGHT_DEV_DIR/config"
    mkdir -p "$MIDNIGHT_DEV_DIR/bin"
    echo "✅ Midnight development directories created at $MIDNIGHT_DEV_DIR"
fi
EOF

sudo chmod +x /usr/local/bin/ensure-midnight-dev.sh

# Add Midnight dev setup to .bashrc for all users (via /etc/skel)
echo '# Ensure Midnight development environment on shell startup' >> /etc/skel/.bashrc
echo 'if [ -x /usr/local/bin/ensure-midnight-dev.sh ]; then' >> /etc/skel/.bashrc
echo '    /usr/local/bin/ensure-midnight-dev.sh' >> /etc/skel/.bashrc
echo 'fi' >> /etc/skel/.bashrc
echo '' >> /etc/skel/.bashrc

# Also add to existing ubuntu user's .bashrc
if [ -f "/home/ubuntu/.bashrc" ]; then
    if ! grep -q "ensure-midnight-dev.sh" /home/ubuntu/.bashrc; then
        echo '# Ensure Midnight development environment on shell startup' >> /home/ubuntu/.bashrc
        echo 'if [ -x /usr/local/bin/ensure-midnight-dev.sh ]; then' >> /home/ubuntu/.bashrc
        echo '    /usr/local/bin/ensure-midnight-dev.sh' >> /home/ubuntu/.bashrc
        echo 'fi' >> /home/ubuntu/.bashrc
        echo '' >> /home/ubuntu/.bashrc
    fi
fi

echo "✅ npm-based Midnight development environment installed"

# Create Midnight services management script for ubuntu user
cat > /home/ubuntu/midnight-dev/bin/manage-services.sh << 'EOF'
#!/bin/bash
# Midnight Services Management Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
MIDNIGHT_DEV_DIR="/home/ubuntu/midnight-dev"
LOG_DIR="$MIDNIGHT_DEV_DIR/logs"
DATA_DIR="$MIDNIGHT_DEV_DIR/data"

# Service status check
check_service() {
    local service=$1
    local port=$2
    
    if nc -z localhost $port 2>/dev/null; then
        echo -e "${GREEN}✅ $service${NC} (port $port)"
        return 0
    else
        echo -e "${RED}❌ $service${NC} (port $port)"
        return 1
    fi
}

# Start Midnight Node function
start_node() {
    echo "🔗 Starting Midnight Node (v0.8.0 dev mode)..."
    cd /usr/local/bin
    
    export CFG_PRESET=dev
    export RUST_BACKTRACE=full
    
    nohup midnight-node --rpc-port 9944 \
        > /home/ubuntu/midnight-dev/logs/midnight-node.log 2>&1 &
    echo $! > /home/ubuntu/midnight-dev/data/midnight-node.pid
    sleep 10
}

# Start Proof Server function
start_proof() {
    echo "🔐 Starting Proof Server..."
    cd /opt/midnight-dev
    
    export RUST_BACKTRACE=full
    
    nohup midnight-proof-server --port 8081 \
        > /home/ubuntu/midnight-dev/logs/proof-server.log 2>&1 &
    echo $! > /home/ubuntu/midnight-dev/data/proof-server.pid
    sleep 3
}

# Start Indexer function
start_indexer() {
    echo "📊 Starting Indexer..."
    cd /home/ubuntu/midnight-dev
    
    export LOG_LEVEL=INFO
    export LEDGER_NETWORK_ID=TestNet
    export SUBSTRATE_NODE_WS_URL=ws://localhost:9944
    export OTEL_JAVAAGENT_ENABLED=false
    
    # Ensure data directory exists and has proper permissions
    mkdir -p /home/ubuntu/midnight-dev/data
    
    nohup midnight-pubsub-indexer --config /home/ubuntu/midnight-dev/config/indexer-simple.yaml \
        > /home/ubuntu/midnight-dev/logs/indexer.log 2>&1 &
    echo $! > /home/ubuntu/midnight-dev/data/indexer.pid
    sleep 5
}

# Start all services
start_all() {
    start_node
    start_proof
    start_indexer
    
    echo ""
    echo -e "${GREEN}✅ Midnight Development Stack started successfully!${NC}"
    echo ""
    echo -e "${BLUE}🌐 Available Services:${NC}"
    echo -e "  🔗 Midnight Node: http://localhost:9944"
    echo -e "  🔐 Proof Server: http://localhost:8081"
    echo -e "  📊 Indexer API: http://localhost:8088"
    echo ""
    echo -e "${BLUE}🔧 Management Commands:${NC}"
    echo -e "  midnight-dev status    # Show service status"
    echo -e "  midnight-dev logs     # Show logs (node/proof/indexer/all)"
    echo -e "  midnight-dev restart  # Restart all services"
}

# Stop all services
stop_all() {
    echo "🛑 Stopping Midnight services..."
    
    if [ -f /home/ubuntu/midnight-dev/data/midnight-node.pid ]; then
        kill $(cat /home/ubuntu/midnight-dev/data/midnight-node.pid) 2>/dev/null || true
        rm -f /home/ubuntu/midnight-dev/data/midnight-node.pid
    fi
    
    if [ -f /home/ubuntu/midnight-dev/data/proof-server.pid ]; then
        kill $(cat /home/ubuntu/midnight-dev/data/proof-server.pid) 2>/dev/null || true
        rm -f /home/ubuntu/midnight-dev/data/proof-server.pid
    fi
    
    if [ -f /home/ubuntu/midnight-dev/data/indexer.pid ]; then
        kill $(cat /home/ubuntu/midnight-dev/data/indexer.pid) 2>/dev/null || true
        rm -f /home/ubuntu/midnight-dev/data/indexer.pid
    fi
    
    echo -e "${GREEN}✅ Midnight services stopped${NC}"
}

# Restart all services
restart_all() {
    stop_all
    sleep 2
    start_all
}

# Show service status
show_status() {
    echo -e "${BLUE}🌙 Midnight Development Stack Status (Dev Mode)${NC}"
    echo ""
    check_service "Midnight Node" 9944
    check_service "Proof Server" 8081
    check_service "Indexer API" 8088
    echo ""
}

# Show logs
show_logs() {
    local service=${1:-all}
    
    case $service in
        node)
            echo -e "${BLUE}🔗 Midnight Node Logs:${NC}"
            tail -f /home/ubuntu/midnight-dev/logs/midnight-node.log 2>/dev/null || echo "No logs found"
            ;;
        proof)
            echo -e "${BLUE}🔐 Proof Server Logs:${NC}"
            tail -f /home/ubuntu/midnight-dev/logs/proof-server.log 2>/dev/null || echo "No logs found"
            ;;
        indexer)
            echo -e "${BLUE}📊 Indexer Logs:${NC}"
            tail -f /home/ubuntu/midnight-dev/logs/indexer.log 2>/dev/null || echo "No logs found"
            ;;
        all)
            echo -e "${BLUE}🌙 All Midnight Services Logs:${NC}"
            tail -f /home/ubuntu/midnight-dev/logs/*.log 2>/dev/null || echo "No logs found"
            ;;
        *)
            echo "Usage: midnight-dev logs [node|proof|indexer|all]"
            exit 1
            ;;
    esac
}

# Main logic
case "${1:-start}" in
    start)
        start_all
        ;;
    stop)
        stop_all
        ;;
    restart)
        restart_all
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    *)
        echo "Usage: manage-services.sh [start|stop|restart|status|logs] [service]"
        echo "Services: node, proof, indexer, all"
        exit 1
        ;;
esac
EOF

chmod +x /home/ubuntu/midnight-dev/bin/manage-services.sh

# Create midnight-dev symlink in user's local bin
mkdir -p /home/ubuntu/.local/bin
ln -sf /home/ubuntu/midnight-dev/bin/manage-services.sh /home/ubuntu/.local/bin/midnight-dev

# Add user's local bin to PATH if not already there
if ! echo $PATH | grep -q "/home/ubuntu/.local/bin"; then
    echo 'export PATH="/home/ubuntu/.local/bin:$PATH"' >> /home/ubuntu/.bashrc
fi

# Also set up for user directory if it exists (fallback)
if [ -d "/home/user" ]; then
    chmod +x /home/user/midnight-dev/bin/manage-services.sh
    mkdir -p /home/user/.local/bin
    ln -sf /home/user/midnight-dev/bin/manage-services.sh /home/user/.local/bin/midnight-dev
    if ! echo $PATH | grep -q "/home/user/.local/bin"; then
        echo 'export PATH="/home/user/.local/bin:$PATH"' >> /home/user/.bashrc
    fi
fi

# Create Midnight project initialization script
sudo tee /usr/local/bin/init-midnight-project > /dev/null << 'EOF'
#!/bin/bash
# Initialize a new Midnight smart contract project

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get the current user's home directory
CURRENT_USER=$(whoami)
CURRENT_HOME=$(eval echo "~$CURRENT_USER")

PROJECT_NAME=${1:-"midnight-contract"}

echo -e "${BLUE}🌙 Initializing Midnight Project: ${PROJECT_NAME}${NC}"

# Check if project directory already exists
if [ -d "$PROJECT_NAME" ]; then
    echo -e "${YELLOW}⚠️  Directory '$PROJECT_NAME' already exists${NC}"
    exit 1
fi

# Create project from template
if [ -d "$CURRENT_HOME/midnight-dev/templates/compact-contract" ]; then
    echo -e "${GREEN}📁 Creating project from template...${NC}"
    cp -r "$CURRENT_HOME/midnight-dev/templates/compact-contract" "$PROJECT_NAME"
else
    echo -e "${YELLOW}⚠️  Template not found, creating basic project...${NC}"
    mkdir -p "$PROJECT_NAME/src/contracts"
    mkdir -p "$PROJECT_NAME/dist/contracts"
    
    # Create basic package.json with working compilation
    cat > "$PROJECT_NAME/package.json" << PKGJSON
{
  "name": "$PROJECT_NAME",
  "version": "1.0.0",
  "description": "Midnight Smart Contract",
  "scripts": {
    "compile": "mkdir -p dist/contracts && node scripts/compile-contracts.js",
    "build": "npm run compile",
    "clean": "rm -rf dist"
  },
  "devDependencies": {},
  "keywords": ["midnight", "blockchain", "smart-contract"],
  "author": "Midnight Developer",
  "license": "MIT"
}
PKGJSON
    
    # Create compilation script
    mkdir -p "$PROJECT_NAME/scripts"
    cat > "$PROJECT_NAME/scripts/compile-contracts.js" << 'COMPILESCRIPT'
#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const contractsDir = path.join(__dirname, '../src/contracts');
const distDir = path.join(__dirname, '../dist/contracts');

// Ensure output directory exists
if (!fs.existsSync(distDir)) {
  fs.mkdirSync(distDir, { recursive: true });
}

// Get all .compact files
const contractFiles = fs.readdirSync(contractsDir).filter(file => file.endsWith('.compact'));

if (contractFiles.length === 0) {
  console.log('⚠️  No .compact files found in src/contracts/');
  process.exit(0);
}

console.log(\`🔨 Compiling \${contractFiles.length} contract(s)...\`);

contractFiles.forEach(file => {
  const contractPath = path.join(contractsDir, file);
  const contractName = path.basename(file, '.compact');
  const contractOutputDir = path.join(distDir, contractName);
  const contractMetadataDir = path.join(distDir, contractName + '.compact');
  
  console.log(\`\n📄 Compiling \${file}...\`);
  
  // Create output directory for this contract (without .compact extension)
  if (!fs.existsSync(contractOutputDir)) {
    fs.mkdirSync(contractOutputDir, { recursive: true });
  }
  
  // Create metadata directory with .compact extension where compiler expects it
  if (!fs.existsSync(contractMetadataDir)) {
    fs.mkdirSync(contractMetadataDir, { recursive: true });
  }
  
  // Create the compiler directory and contract-info.json that compactc expects
  const compilerDir = path.join(contractMetadataDir, 'compiler');
  if (!fs.existsSync(compilerDir)) {
    fs.mkdirSync(compilerDir, { recursive: true });
  }
  
  // Create contract-info.json with correct format from analysis
  const contractInfo = {
    name: contractName,
    version: "1.0.0",
    compiler: "0.26.0",
    contracts: [contractName],
    circuits: []
  };
  fs.writeFileSync(
    path.join(compilerDir, 'contract-info.json'),
    JSON.stringify(contractInfo, null, 2)
  );
  
  try {
    // Compile using Compact CLI with timeout
    execSync(\`compact compile "\${contractPath}" "\${contractOutputDir}"\`, {
      stdio: 'inherit',
      cwd: __dirname + '/..',
      timeout: 60000 // 60 second timeout for CLI
    });
    
    console.log(\`✅ \${file} compiled successfully\`);
    
    // List generated files
    const generatedFiles = fs.readdirSync(contractOutputDir);
    console.log(\`📁 Generated files: \${generatedFiles.join(', ')}\`);
    
  } catch (error) {
    console.error(\`❌ Failed to compile \${file}:\`, error.message);
    if (error.signal === 'SIGTERM') {
      console.error(\`⏱️  Compilation timed out - this may indicate a compiler issue\`);
    }
    process.exit(1);
  }
});

console.log('\n✅ All contracts compiled successfully!');
COMPILESCRIPT
    
    chmod +x "$PROJECT_NAME/scripts/compile-contracts.js"
    
    # Create example contract with correct Compact syntax
    cat > "$PROJECT_NAME/src/contracts/Example.compact" << 'CONTRACT'
// Example Midnight Smart Contract
// Note: Use 'circuit' instead of 'function', with explicit types and semicolons
contract Example {
  circuit main(x : Field) : Field;
}
CONTRACT
fi

# Update package.json with project name
sed -i "s/midnight-contract-template/$PROJECT_NAME/g" "$PROJECT_NAME/package.json"

cd "$PROJECT_NAME"

echo -e "${GREEN}📦 Installing dependencies...${NC}"
npm install

echo -e "${GREEN}✅ Midnight project initialized successfully!${NC}"
echo ""
echo -e "${BLUE}🚀 Next steps:${NC}"
echo -e "  cd $PROJECT_NAME"
echo -e "  # Edit contracts in src/contracts/"
echo -e "  npm run compile    # Compile contracts"
echo -e "  npm run build      # Build project"
echo ""
echo -e "${BLUE}📚 Project structure:${NC}"
echo -e "  src/contracts/     # Your .compact contract files"
echo -e "  dist/contracts/    # Compiled contract outputs"
echo -e "  package.json        # NPM configuration"
EOF

sudo chmod +x /usr/local/bin/init-midnight-project

# Fix ownership of all ubuntu user files
chown -R ubuntu:ubuntu /home/ubuntu 2>/dev/null || true

# Also fix user directory if it exists
if [ -d "/home/user" ]; then
    chown -R user:user /home/user 2>/dev/null || true
fi

echo "✅ Midnight Vibe Platform setup complete!"