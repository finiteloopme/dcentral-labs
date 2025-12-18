import { Command } from 'commander';
import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';
import { execSync } from 'child_process';
import { logger } from '../utils/logger.js';

// Template files embedded as strings
const templates = {
  'contracts/counter.compact': `// Counter - A simple Midnight smart contract example
//
// This contract demonstrates basic state management with a counter
// that can be incremented and read.

pragma language_version >= 0.18.0;

// Ledger state - persisted on-chain
ledger counter: Counter;

// Counter state structure
struct Counter {
  value: Uint<64>;
}

// Increment the counter by 1
export circuit increment(): [] {
  counter = Counter { value: (counter.value + 1) as Uint<64> };
}

// Get the current counter value
export circuit get_value(): Uint<64> {
  return counter.value;
}
`,

  'src/index.ts': `import { Counter } from './contract';

async function main() {
  console.log('Midnight Counter Example');
  console.log('========================');
  
  // TODO: Initialize contract and interact with it
  // This requires the Midnight SDK and a running network
  
  console.log('Contract deployment and interaction coming soon...');
}

main().catch(console.error);
`,

  'src/contract.ts': `// Contract bindings will be generated after compilation
// Run: midnightctl compile

export interface Counter {
  increment(): Promise<void>;
  getValue(): Promise<number>;
}
`,

  'tests/counter.test.ts': `import { describe, it, expect } from '@jest/globals';

describe('Counter Contract', () => {
  it('should increment the counter', async () => {
    // TODO: Add contract tests
    expect(true).toBe(true);
  });

  it('should return the current value', async () => {
    // TODO: Add contract tests
    expect(true).toBe(true);
  });
});
`,

  'package.json': `{
  "name": "{{PROJECT_NAME}}",
  "version": "0.1.0",
  "description": "Midnight smart contract project",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc",
    "compile": "midnightctl compile",
    "test": "jest",
    "start": "ts-node src/index.ts"
  },
  "keywords": ["midnight", "smart-contract", "zero-knowledge"],
  "license": "MIT",
  "dependencies": {},
  "devDependencies": {
    "@types/node": "^20.10.0",
    "typescript": "^5.3.0",
    "ts-node": "^10.9.0",
    "jest": "^29.7.0",
    "@jest/globals": "^29.7.0",
    "ts-jest": "^29.1.0"
  }
}
`,

  'tsconfig.json': `{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
`,

  'midnight.config.json': `{
  "project": {
    "name": "{{PROJECT_NAME}}",
    "version": "0.1.0"
  },
  "contracts": {
    "source": "./contracts",
    "output": "./build"
  },
  "chainEnvironment": "standalone"
}
`,

  // Note: Service URLs are configured via environment variables, not in this file.
  // See .env.example in the platform root for configuration options.
  // In GCP Workstation, URLs are injected automatically by Terraform.

  '.gitignore': `# Dependencies
node_modules/

# Build outputs
dist/
build/

# Private data (wallets, contract state)
# Contains sensitive data - never commit!
.private/

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Environment
.env
.env.local

# Logs
*.log
npm-debug.log*
`,

  'README.md': `# {{PROJECT_NAME}}

A Midnight smart contract project.

## Getting Started

### Prerequisites

- Node.js 18+
- Midnight CLI (\`midnightctl\`)
- Running Midnight services

### Installation

\`\`\`bash
npm install
\`\`\`

### Compile Contracts

\`\`\`bash
midnightctl compile
# or
npm run compile
\`\`\`

### Run Tests

\`\`\`bash
npm test
\`\`\`

### Start Development

\`\`\`bash
npm start
\`\`\`

## Project Structure

\`\`\`
├── contracts/          # Compact smart contracts
│   └── counter.compact # Example counter contract
├── src/                # TypeScript source code
│   ├── index.ts        # Main entry point
│   └── contract.ts     # Contract bindings
├── tests/              # Test files
├── build/              # Compiled contract output
├── .private/           # Wallet & contract state (gitignored)
└── midnight.config.json # Project configuration
\`\`\`

## Wallet Management

\`\`\`bash
# Create a new wallet
midnightctl wallet create dev-wallet

# Check wallet balance
midnightctl wallet balance

# Fund wallet (standalone/devnet only)
midnightctl wallet fund dev-wallet 10000
\`\`\`

## Contract Deployment

\`\`\`bash
# Compile and deploy
midnightctl compile
midnightctl contract deploy ./build/counter --wallet dev-wallet
\`\`\`

## Resources

- [Midnight Documentation](https://docs.midnight.network)
- [Compact Language Guide](https://docs.midnight.network/compact)
`,
};

function createProject(projectPath: string, projectName: string): void {
  // Create project directory
  if (fs.existsSync(projectPath)) {
    throw new Error(`Directory '${projectPath}' already exists`);
  }
  
  fs.mkdirSync(projectPath, { recursive: true });
  
  // Create subdirectories
  const dirs = ['contracts', 'src', 'tests', 'build'];
  for (const dir of dirs) {
    fs.mkdirSync(path.join(projectPath, dir), { recursive: true });
  }
  
  // Write template files
  for (const [filePath, content] of Object.entries(templates)) {
    const fullPath = path.join(projectPath, filePath);
    const fileContent = content.replace(/\{\{PROJECT_NAME\}\}/g, projectName);
    
    // Ensure directory exists
    fs.mkdirSync(path.dirname(fullPath), { recursive: true });
    fs.writeFileSync(fullPath, fileContent);
    logger.step(`Created ${filePath}`);
  }
}

function installDependencies(projectPath: string): void {
  logger.info('Installing dependencies...');
  
  try {
    execSync('npm install', {
      cwd: projectPath,
      stdio: 'inherit',
    });
    logger.success('Dependencies installed');
  } catch (error) {
    logger.warning('Failed to install dependencies. Run "npm install" manually.');
  }
}

function generateIndexerSecret(): string {
  return crypto.randomBytes(32).toString('hex');
}

function createEnvFile(projectPath: string): void {
  console.log('');
  logger.info('Creating .env file...');
  
  // Check environment variables first, then fall back to localhost defaults
  // In GCP Workstation, these are injected by Terraform
  const nodeUrl = process.env.MIDNIGHT_NODE_URL || 'ws://localhost:9944';
  const indexerUrl = process.env.INDEXER_URL || 'http://localhost:8088';
  const proofServerUrl = process.env.PROOF_SERVER_URL || 'http://localhost:6300';
  const secret = process.env.INDEXER_SECRET || generateIndexerSecret();
  
  const usingEnvVars = !!(process.env.MIDNIGHT_NODE_URL || process.env.INDEXER_URL || process.env.PROOF_SERVER_URL);
  const source = usingEnvVars ? 'environment variables' : 'localhost defaults';
  
  if (usingEnvVars) {
    logger.success('Using service URLs from environment');
  } else {
    logger.info('Using localhost defaults (set MIDNIGHT_NODE_URL, INDEXER_URL, PROOF_SERVER_URL to override)');
  }
  
  const envContent = `# Midnight Service Configuration
# Auto-generated by midnightctl init
# Source: ${source}

# Service URLs
# In GCP Workstation, these are injected automatically by Terraform.
# For local development, update these to point to your running services.
MIDNIGHT_NODE_URL=${nodeUrl}
INDEXER_URL=${indexerUrl}
PROOF_SERVER_URL=${proofServerUrl}

# Chain environment
CHAIN_ENVIRONMENT=standalone

# Indexer secret - 32-byte hex string for encryption
# Auto-generated. You can regenerate with: openssl rand -hex 32
INDEXER_SECRET=${secret}
`;

  fs.writeFileSync(path.join(projectPath, '.env'), envContent);
  logger.step(`Created .env (using ${source})`);
}

export const initCommand = new Command('init')
  .description('Create a new Midnight project')
  .argument('<name>', 'Project name')
  .option('-t, --template <template>', 'Project template', 'counter')
  .option('--no-install', 'Skip npm install')
  .action((name: string, options: { template: string; install: boolean }) => {
    logger.title(`Creating Midnight project: ${name}`);
    
    const projectPath = path.resolve(process.cwd(), name);
    
    try {
      // Create project from template
      logger.info(`Using template: ${options.template}`);
      createProject(projectPath, name);
      
      // Create .env file with service URLs
      createEnvFile(projectPath);
      
      // Install dependencies
      if (options.install) {
        installDependencies(projectPath);
      }
      
      // Success message
      console.log('');
      logger.success(`Project created successfully!`);
      console.log('');
      console.log(`  cd ${name}`);
      console.log('  midnightctl compile    # Compile contracts');
      console.log('  npm start              # Run the project');
      console.log('');
    } catch (error) {
      logger.error((error as Error).message);
      process.exit(1);
    }
  });
