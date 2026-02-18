/**
 * compact_compile tool
 *
 * Compiles Compact smart contract source code to ZK circuits
 * using the compactc compiler binary.
 *
 * The compactc binary is installed separately from the toolkit and is
 * version-pinned to match the Midnight node compatibility matrix.
 *
 * Input:  Compact source code string
 * Output: Compiled artifacts (JS, .d.ts, contract-info.json, zkir, keys)
 *
 * compactc CLI usage: compactc [FLAGS] <sourcepath> <targetpath>
 *   FLAGS:
 *     --skip-zk  Skip ZK proof key generation (faster compilation)
 *     --version  Print compiler version
 */

import { writeFile, readFile, mkdir, rm, readdir, stat } from 'fs/promises';
import { join } from 'path';
import { tmpdir } from 'os';
import { randomUUID } from 'crypto';
import { spawn } from 'child_process';
import type { MidnightMCPConfig } from '../config.js';

/**
 * Run the compactc compiler binary.
 *
 * @param args - Arguments to pass to compactc
 * @returns Result with stdout, stderr, and success flag
 */
async function runCompactc(args: string[]): Promise<{
  success: boolean;
  stdout: string;
  stderr: string;
  error?: string;
}> {
  const compactcPath = process.env.COMPACTC_PATH || 'compactc';

  return new Promise((resolve) => {
    const proc = spawn(compactcPath, args, {
      env: { ...process.env },
      stdio: ['pipe', 'pipe', 'pipe'],
    });

    let stdout = '';
    let stderr = '';

    proc.stdout.on('data', (data) => {
      stdout += data.toString();
    });

    proc.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    proc.on('error', (err) => {
      resolve({
        success: false,
        stdout,
        stderr,
        error: `Failed to spawn compactc: ${err.message}`,
      });
    });

    proc.on('close', (code) => {
      resolve({
        success: code === 0,
        stdout,
        stderr,
        error: code !== 0 ? `compactc exited with code ${code}` : undefined,
      });
    });
  });
}

export interface CompileResult {
  success: boolean;
  message: string;
  /** Path to the compile output directory (contains managed/<contractName>/) */
  compiledDir: string;
  artifacts: Array<{
    filename: string;
    content: string;
    mimeType: string;
  }>;
  errors?: string;
}

export async function compileCompact(
  source: string,
  _config: MidnightMCPConfig
): Promise<CompileResult> {
  // Validate basic structure
  if (!source.includes('pragma language_version')) {
    return {
      success: false,
      message:
        'Invalid Compact code: missing pragma language_version declaration.',
      compiledDir: '',
      artifacts: [],
      errors:
        'Compact source must start with a pragma language_version directive, e.g. pragma language_version 0.20;',
    };
  }

  // Check for standard library import (required for most contracts)
  if (!source.includes('import CompactStandardLibrary')) {
    console.log(
      '[compact_compile] Warning: Contract does not import CompactStandardLibrary. Most contracts need this.'
    );
  }

  const tempDir = join(tmpdir(), `compact-${randomUUID()}`);
  const contractPath = join(tempDir, 'contract.compact');
  const outputDir = join(tempDir, 'output');

  try {
    await mkdir(tempDir, { recursive: true });
    await mkdir(outputDir, { recursive: true });
    await writeFile(contractPath, source, 'utf-8');

    // Run compactc compiler directly
    // Usage: compactc [FLAGS] <sourcepath> <targetpath>
    // We use --skip-zk by default for faster compilation during development.
    // The ZK keys can be generated separately if needed for deployment.
    const skipZk = process.env.COMPACTC_SKIP_ZK !== 'false';
    const args = skipZk
      ? ['--skip-zk', contractPath, outputDir]
      : [contractPath, outputDir];

    console.log(`[compact_compile] Running: compactc ${args.join(' ')}`);
    const result = await runCompactc(args);

    if (!result.success) {
      // Clean up on failure
      try {
        await rm(tempDir, { recursive: true, force: true });
      } catch {
        // Ignore cleanup errors
      }

      return {
        success: false,
        message: `Compilation failed: ${result.error || result.stderr}`,
        compiledDir: '',
        artifacts: [],
        errors: result.error || result.stderr,
      };
    }

    if (result.stdout) {
      console.log('[compact_compile] stdout:', result.stdout);
    }
    if (result.stderr) {
      console.log('[compact_compile] stderr:', result.stderr);
    }

    // Read output files
    // compactc output structure:
    //   contract/index.cjs      - JavaScript contract code
    //   contract/index.d.cts    - TypeScript type definitions
    //   contract/index.cjs.map  - Source map
    //   zkir/*.zkir             - ZK circuit intermediate representation
    //   keys/*.prover           - Prover keys (binary, skip)
    //   keys/*.verifier         - Verifier keys (binary, skip)
    const artifacts: CompileResult['artifacts'] = [];

    // Helper to get MIME type for a file
    const getMimeType = (filename: string): string => {
      if (filename.endsWith('.json')) return 'application/json';
      if (filename.endsWith('.d.cts') || filename.endsWith('.d.ts'))
        return 'text/typescript';
      if (filename.endsWith('.cjs') || filename.endsWith('.js'))
        return 'text/javascript';
      if (filename.endsWith('.zkir')) return 'application/octet-stream';
      if (filename.endsWith('.map')) return 'application/json';
      return 'text/plain';
    };

    // Helper to check if file is binary (keys are binary, skip them)
    const isBinaryFile = (filename: string): boolean => {
      return filename.endsWith('.prover') || filename.endsWith('.verifier');
    };

    // Recursively read all text files from output directory
    try {
      const files = await readdir(outputDir, { recursive: true });
      for (const file of files) {
        const filename = file.toString();
        const filePath = join(outputDir, filename);

        // Skip binary files
        if (isBinaryFile(filename)) {
          console.log(`[compact_compile] Skipping binary file: ${filename}`);
          continue;
        }

        // Check if it's a file (not a directory)
        try {
          const fileStat = await stat(filePath);
          if (!fileStat.isFile()) continue;

          const content = await readFile(filePath, 'utf-8');
          artifacts.push({
            filename,
            content,
            mimeType: getMimeType(filename),
          });
        } catch {
          // Skip unreadable files
          console.log(`[compact_compile] Could not read: ${filename}`);
        }
      }
    } catch (readError) {
      console.error(
        '[compact_compile] Error reading output directory:',
        readError
      );
    }

    // NOTE: We do NOT delete the temp dir on success because contract_deploy
    // needs to read the compiled artifacts from outputDir/managed/<name>/.
    // The temp dir will be cleaned up when the OS cleans /tmp, or by the
    // caller if they no longer need the artifacts.
    return {
      success: true,
      message: `Contract compiled successfully. ${artifacts.length} artifact(s) generated.`,
      compiledDir: outputDir,
      artifacts,
    };
  } catch (error) {
    const err = error as { stderr?: string; message?: string };
    const errorMessage =
      err.stderr || err.message || 'Unknown compilation error';

    // Clean up on failure
    try {
      await rm(tempDir, { recursive: true, force: true });
    } catch {
      // Ignore cleanup errors
    }

    return {
      success: false,
      message: `Compilation failed: ${errorMessage}`,
      compiledDir: '',
      artifacts: [],
      errors: errorMessage,
    };
  }
}
