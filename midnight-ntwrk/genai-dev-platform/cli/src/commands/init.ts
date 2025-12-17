import { Command } from 'commander';
import * as fs from 'fs';
import * as path from 'path';
import { execSync } from 'child_process';
import { logger } from '../utils/logger';

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
  "chainEnvironment": {
    "default": "standalone",
    "environments": {
      "standalone": {
        "nodeUrl": "ws://localhost:9944",
        "indexerUrl": "http://localhost:8088",
        "proofServerUrl": "http://localhost:6300"
      },
      "testnet": {
        "nodeUrl": "wss://testnet-node.midnight.network",
        "indexerUrl": "https://testnet-indexer.midnight.network",
        "proofServerUrl": "http://localhost:6300"
      },
      "mainnet": {
        "nodeUrl": "wss://mainnet-node.midnight.network",
        "indexerUrl": "https://mainnet-indexer.midnight.network",
        "proofServerUrl": "http://localhost:6300"
      }
    }
  }
}
`,

  '.gitignore': `# Dependencies
node_modules/

# Build outputs
dist/
build/

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
└── midnight.config.json # Project configuration
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
