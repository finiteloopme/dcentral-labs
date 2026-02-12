/**
 * Compile Compact Contract Skill
 *
 * Compiles Compact smart contract source code to ZK circuits
 * using the Compact compiler (compactc).
 */

import type { Message } from '@a2a-js/sdk';
import { exec } from 'child_process';
import { promisify } from 'util';
import { writeFile, readFile, mkdir, rm } from 'fs/promises';
import { join } from 'path';
import { tmpdir } from 'os';
import { randomUUID } from 'crypto';
import type { SkillEvent } from './index.js';
import { extractTextFromMessage } from './index.js';

const execAsync = promisify(exec);

/**
 * Extract Compact code from a message
 * Looks for code blocks or file artifacts
 */
function extractCompactCode(message: Message): string | null {
  const text = extractTextFromMessage(message);

  // Try to extract from ```compact code block
  const compactMatch = text.match(/```compact\n([\s\S]*?)```/);
  if (compactMatch) {
    return compactMatch[1].trim();
  }

  // Try to extract from generic code block
  const codeMatch = text.match(/```\n?([\s\S]*?)```/);
  if (codeMatch) {
    return codeMatch[1].trim();
  }

  // Check for file artifacts in the message
  for (const part of message.parts) {
    if ('kind' in part && part.kind === 'file') {
      const filePart = part as { kind: 'file'; name?: string; data?: string };
      if (filePart.name?.endsWith('.compact') && filePart.data) {
        return filePart.data;
      }
    }
  }

  // If the text looks like Compact code (starts with pragma), use it directly
  if (text.includes('pragma language_version')) {
    return text;
  }

  return null;
}

/**
 * Compile Compact source code
 */
export async function* compileCompact(
  message: Message
): AsyncGenerator<SkillEvent, void, unknown> {
  yield { type: 'status', message: 'Extracting Compact code...' };

  // Extract Compact code from the message
  const compactCode = extractCompactCode(message);

  if (!compactCode) {
    yield {
      type: 'error',
      message:
        'No Compact code found in the message. Please provide code in a ```compact code block or as a .compact file.',
    };
    return;
  }

  // Validate basic structure
  if (!compactCode.includes('pragma language_version')) {
    yield {
      type: 'error',
      message:
        'Invalid Compact code: missing pragma language_version declaration.',
    };
    return;
  }

  yield { type: 'status', message: 'Setting up compilation environment...' };

  // Create temporary directory for compilation
  const tempDir = join(tmpdir(), `compact-${randomUUID()}`);
  const contractPath = join(tempDir, 'contract.compact');
  const outputDir = join(tempDir, 'output');

  try {
    // Create directories
    await mkdir(tempDir, { recursive: true });
    await mkdir(outputDir, { recursive: true });

    // Write the Compact code to file
    await writeFile(contractPath, compactCode, 'utf-8');

    yield { type: 'status', message: 'Compiling Compact contract...' };

    // Run the Compact compiler
    // compact compile <input> <output-dir>
    const compileCommand = `compact build "${contractPath}" --output "${outputDir}"`;

    try {
      const { stdout, stderr } = await execAsync(compileCommand, {
        timeout: 120000, // 2 minute timeout
        cwd: tempDir,
      });

      // Log compiler output
      if (stdout) {
        console.log('[compile] stdout:', stdout);
      }
      if (stderr) {
        console.log('[compile] stderr:', stderr);
      }

      yield { type: 'status', message: 'Compilation successful!' };

      // Read and emit output files
      const outputFiles = [
        'contract.js',
        'contract.d.ts',
        'contract-info.json',
      ];

      for (const filename of outputFiles) {
        try {
          const filePath = join(outputDir, filename);
          const content = await readFile(filePath, 'utf-8');
          yield {
            type: 'artifact',
            name: filename,
            content,
            mimeType: filename.endsWith('.json')
              ? 'application/json'
              : 'text/javascript',
          };
        } catch {
          // File might not exist, skip
          console.log(`[compile] Output file not found: ${filename}`);
        }
      }

      yield {
        type: 'result',
        data: {
          success: true,
          message: 'Contract compiled successfully',
          outputDir,
        },
        message: 'Compact contract compiled successfully',
      };
    } catch (execError) {
      const error = execError as { stderr?: string; message?: string };
      const errorMessage = error.stderr || error.message || 'Unknown error';

      console.error('[compile] Compilation failed:', errorMessage);

      yield {
        type: 'artifact',
        name: 'compile-error.txt',
        content: errorMessage,
        mimeType: 'text/plain',
      };

      yield {
        type: 'error',
        message: `Compilation failed: ${errorMessage}`,
      };
    }
  } finally {
    // Clean up temporary directory
    try {
      await rm(tempDir, { recursive: true, force: true });
    } catch {
      // Ignore cleanup errors
    }
  }
}
