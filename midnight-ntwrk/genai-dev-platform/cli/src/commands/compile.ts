import { Command } from 'commander';
import * as fs from 'fs';
import * as path from 'path';
import { execSync, spawnSync } from 'child_process';
import { logger } from '../utils/logger';

interface MidnightConfig {
  contracts?: {
    source?: string;
    output?: string;
  };
}

function findCompactFiles(dir: string): string[] {
  const files: string[] = [];
  
  if (!fs.existsSync(dir)) {
    return files;
  }
  
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...findCompactFiles(fullPath));
    } else if (entry.name.endsWith('.compact')) {
      files.push(fullPath);
    }
  }
  
  return files;
}

function loadConfig(projectDir: string): MidnightConfig {
  const configPath = path.join(projectDir, 'midnight.config.json');
  
  if (fs.existsSync(configPath)) {
    const content = fs.readFileSync(configPath, 'utf-8');
    return JSON.parse(content);
  }
  
  return {};
}

function checkCompactInstalled(): boolean {
  const result = spawnSync('compact', ['--version'], {
    encoding: 'utf-8',
    stdio: 'pipe',
  });
  
  return result.status === 0;
}

function compileContract(
  contractPath: string,
  outputDir: string
): boolean {
  const contractName = path.basename(contractPath, '.compact');
  const outputPath = path.join(outputDir, contractName);
  
  logger.step(`Compiling ${path.basename(contractPath)}...`);
  
  try {
    // Ensure output directory exists
    fs.mkdirSync(outputPath, { recursive: true });
    
    // Run the compact compiler
    // The compact CLI expects: compact compile <source> <output>
    const result = execSync(`compact compile "${contractPath}" "${outputPath}"`, {
      encoding: 'utf-8',
      stdio: 'pipe',
      env: {
        ...process.env,
        COMPACT_DIRECTORY: process.env.COMPACT_DIRECTORY || '/usr/local/share/compact-compilers',
      },
    });
    
    if (result) {
      console.log(result);
    }
    
    logger.success(`Compiled: ${contractName}`);
    return true;
  } catch (error: any) {
    logger.error(`Failed to compile ${contractName}`);
    if (error.stderr) {
      console.error(error.stderr);
    } else if (error.stdout) {
      console.error(error.stdout);
    } else if (error.message) {
      console.error(error.message);
    }
    return false;
  }
}

export const compileCommand = new Command('compile')
  .description('Compile Compact smart contracts')
  .option('-s, --source <dir>', 'Source directory for contracts')
  .option('-o, --output <dir>', 'Output directory for compiled contracts')
  .option('-w, --watch', 'Watch for changes and recompile')
  .action((options: { source?: string; output?: string; watch?: boolean }) => {
    const projectDir = process.cwd();
    
    logger.title('Compiling Midnight Contracts');
    
    // Check if compact is installed
    if (!checkCompactInstalled()) {
      logger.error('Compact compiler not found.');
      logger.info('Make sure the compact compiler is installed and in your PATH.');
      process.exit(1);
    }
    
    // Load config
    const config = loadConfig(projectDir);
    
    // Determine source and output directories
    const sourceDir = options.source || config.contracts?.source || './contracts';
    const outputDir = options.output || config.contracts?.output || './build';
    
    const fullSourceDir = path.resolve(projectDir, sourceDir);
    const fullOutputDir = path.resolve(projectDir, outputDir);
    
    logger.info(`Source: ${sourceDir}`);
    logger.info(`Output: ${outputDir}`);
    console.log('');
    
    // Find all .compact files
    const contractFiles = findCompactFiles(fullSourceDir);
    
    if (contractFiles.length === 0) {
      logger.warning(`No .compact files found in ${sourceDir}`);
      process.exit(0);
    }
    
    logger.info(`Found ${contractFiles.length} contract(s)`);
    console.log('');
    
    // Compile each contract
    let successCount = 0;
    let failCount = 0;
    
    for (const contractPath of contractFiles) {
      if (compileContract(contractPath, fullOutputDir)) {
        successCount++;
      } else {
        failCount++;
      }
    }
    
    // Summary
    console.log('');
    if (failCount === 0) {
      logger.success(`All ${successCount} contract(s) compiled successfully`);
    } else {
      logger.warning(`Compiled: ${successCount}, Failed: ${failCount}`);
      process.exit(1);
    }
    
    // Watch mode
    if (options.watch) {
      logger.info('Watching for changes... (Ctrl+C to stop)');
      
      fs.watch(fullSourceDir, { recursive: true }, (eventType, filename) => {
        if (filename?.endsWith('.compact')) {
          console.log('');
          logger.info(`File changed: ${filename}`);
          const contractPath = path.join(fullSourceDir, filename);
          if (fs.existsSync(contractPath)) {
            compileContract(contractPath, fullOutputDir);
          }
        }
      });
    }
  });
