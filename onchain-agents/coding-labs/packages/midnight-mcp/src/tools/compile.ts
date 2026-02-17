/**
 * compact_compile tool
 *
 * Compiles Compact smart contract source code to ZK circuits
 * using the Compact compiler CLI.
 *
 * Input:  Compact source code string
 * Output: Compiled artifacts (JS, .d.ts, contract-info.json)
 */

import { exec } from 'child_process';
import { promisify } from 'util';
import { writeFile, readFile, mkdir, rm, readdir } from 'fs/promises';
import { join } from 'path';
import { tmpdir } from 'os';
import { randomUUID } from 'crypto';
import type { MidnightMCPConfig } from '../config.js';

const execAsync = promisify(exec);

export interface CompileResult {
  success: boolean;
  message: string;
  artifacts: Array<{
    filename: string;
    content: string;
    mimeType: string;
  }>;
  errors?: string;
}

export async function compileCompact(
  source: string,
  config: MidnightMCPConfig
): Promise<CompileResult> {
  // Validate basic structure
  if (!source.includes('pragma language_version')) {
    return {
      success: false,
      message:
        'Invalid Compact code: missing pragma language_version declaration.',
      artifacts: [],
      errors:
        'Compact source must start with a pragma language_version directive, e.g. pragma language_version 0.20;',
    };
  }

  const tempDir = join(tmpdir(), `compact-${randomUUID()}`);
  const contractPath = join(tempDir, 'contract.compact');
  const outputDir = join(tempDir, 'output');

  try {
    await mkdir(tempDir, { recursive: true });
    await mkdir(outputDir, { recursive: true });
    await writeFile(contractPath, source, 'utf-8');

    const compileCommand = `${config.compactBinaryPath} compile "${contractPath}" "${outputDir}"`;

    const { stdout, stderr } = await execAsync(compileCommand, {
      timeout: 120_000,
      cwd: tempDir,
    });

    if (stdout) {
      console.log('[compact_compile] stdout:', stdout);
    }
    if (stderr) {
      console.log('[compact_compile] stderr:', stderr);
    }

    // Read output files
    const artifacts: CompileResult['artifacts'] = [];

    // Try to discover actual output files
    try {
      const files = await readdir(outputDir, { recursive: true });
      for (const file of files) {
        const filePath = join(outputDir, file.toString());
        try {
          const content = await readFile(filePath, 'utf-8');
          const filename = file.toString();
          artifacts.push({
            filename,
            content,
            mimeType: filename.endsWith('.json')
              ? 'application/json'
              : filename.endsWith('.d.ts') || filename.endsWith('.ts')
                ? 'text/typescript'
                : 'text/javascript',
          });
        } catch {
          // Skip binary files or unreadable files
        }
      }
    } catch {
      // Fall back to known file names
      const knownFiles = ['contract.js', 'contract.d.ts', 'contract-info.json'];
      for (const filename of knownFiles) {
        try {
          const content = await readFile(join(outputDir, filename), 'utf-8');
          artifacts.push({
            filename,
            content,
            mimeType: filename.endsWith('.json')
              ? 'application/json'
              : 'text/javascript',
          });
        } catch {
          // Skip missing files
        }
      }
    }

    return {
      success: true,
      message: `Contract compiled successfully. ${artifacts.length} artifact(s) generated.`,
      artifacts,
    };
  } catch (error) {
    const err = error as { stderr?: string; message?: string };
    const errorMessage =
      err.stderr || err.message || 'Unknown compilation error';

    return {
      success: false,
      message: `Compilation failed: ${errorMessage}`,
      artifacts: [],
      errors: errorMessage,
    };
  } finally {
    try {
      await rm(tempDir, { recursive: true, force: true });
    } catch {
      // Ignore cleanup errors
    }
  }
}
