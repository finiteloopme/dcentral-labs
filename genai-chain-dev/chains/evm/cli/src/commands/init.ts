/**
 * Init command - scaffold a new project
 */

import { Command } from 'commander';
import { existsSync, mkdirSync, copyFileSync, writeFileSync, readdirSync, statSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import type { ChainConfig } from '../lib/config.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

export function registerInitCommand(program: Command, config: ChainConfig): void {
  program
    .command('init <name>')
    .description('Create a new Foundry project')
    .option('-t, --template <name>', 'Project template to use', 'foundry')
    .action(async (name: string, options: { template: string }) => {
      const projectDir = join(process.cwd(), name);
      
      if (existsSync(projectDir)) {
        console.error(`\n\x1b[31mError:\x1b[0m Directory '${name}' already exists.\n`);
        process.exit(1);
      }
      
      console.log(`\nCreating project '${name}'...\n`);
      
      // Find template directory
      const templateDir = join(__dirname, '..', '..', 'templates', options.template);
      
      // If template doesn't exist, use forge init
      if (!existsSync(templateDir)) {
        console.log('Using forge init...');
        const { spawn } = await import('node:child_process');
        
        await new Promise<void>((resolve, reject) => {
          const child = spawn('forge', ['init', name], {
            stdio: 'inherit',
            cwd: process.cwd(),
          });
          
          child.on('close', (code) => {
            if (code === 0) resolve();
            else reject(new Error(`forge init failed with code ${code}`));
          });
        });
        
        // Add chain-specific .env file
        const envContent = `# ${config.chainName} Configuration
RPC_URL=${config.rpcUrl}
CHAIN_ID=${config.chainId}
${config.explorerUrl ? `EXPLORER_URL=${config.explorerUrl}` : ''}
${config.faucetUrl ? `FAUCET_URL=${config.faucetUrl}` : ''}
`;
        writeFileSync(join(projectDir, '.env'), envContent);
        
        console.log('\n\x1b[32mProject created successfully!\x1b[0m\n');
        console.log('Next steps:');
        console.log(`  cd ${name}`);
        console.log(`  ${config.cliName} compile`);
        console.log(`  ${config.cliName} test`);
        console.log('');
        return;
      }
      
      // Copy template
      mkdirSync(projectDir, { recursive: true });
      copyDir(templateDir, projectDir);
      
      // Update foundry.toml with chain-specific settings
      const foundryToml = join(projectDir, 'foundry.toml');
      if (existsSync(foundryToml)) {
        let content = require('fs').readFileSync(foundryToml, 'utf-8');
        content += `
# ${config.chainName} Configuration
[rpc_endpoints]
${config.chainName.toLowerCase()} = "${config.rpcUrl}"
local = "http://127.0.0.1:8545"
`;
        writeFileSync(foundryToml, content);
      }
      
      // Create .env file
      const envContent = `# ${config.chainName} Configuration
RPC_URL=${config.rpcUrl}
CHAIN_ID=${config.chainId}
${config.explorerUrl ? `EXPLORER_URL=${config.explorerUrl}` : ''}
${config.faucetUrl ? `FAUCET_URL=${config.faucetUrl}` : ''}

# Deployment wallet (set after creating wallet with: ${config.cliName} wallet create)
# PRIVATE_KEY=
`;
      writeFileSync(join(projectDir, '.env'), envContent);
      
      console.log('  Created: ' + name + '/');
      console.log('  Created: ' + name + '/src/');
      console.log('  Created: ' + name + '/script/');
      console.log('  Created: ' + name + '/test/');
      console.log('  Created: ' + name + '/foundry.toml');
      console.log('  Created: ' + name + '/.env');
      
      console.log('\n\x1b[32mProject created successfully!\x1b[0m\n');
      console.log('Next steps:');
      console.log(`  cd ${name}`);
      console.log(`  ${config.cliName} compile`);
      console.log(`  ${config.cliName} test`);
      console.log('');
    });
}

/**
 * Recursively copy a directory
 */
function copyDir(src: string, dest: string): void {
  mkdirSync(dest, { recursive: true });
  
  for (const entry of readdirSync(src)) {
    const srcPath = join(src, entry);
    const destPath = join(dest, entry);
    
    if (statSync(srcPath).isDirectory()) {
      copyDir(srcPath, destPath);
    } else {
      copyFileSync(srcPath, destPath);
    }
  }
}
