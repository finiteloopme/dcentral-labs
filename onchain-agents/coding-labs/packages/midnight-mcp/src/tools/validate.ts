/**
 * compact_validate tool
 *
 * Validates Compact smart contract syntax without full compilation.
 * Uses the compiler in check mode if available, otherwise performs
 * basic structural validation.
 */

import { exec } from 'child_process';
import { promisify } from 'util';
import { writeFile, mkdir, rm } from 'fs/promises';
import { join } from 'path';
import { tmpdir } from 'os';
import { randomUUID } from 'crypto';
import type { MidnightMCPConfig } from '../config.js';

const execAsync = promisify(exec);

export interface ValidateResult {
  valid: boolean;
  message: string;
  errors: string[];
  warnings: string[];
}

/**
 * Basic structural validation of Compact source code.
 */
function structuralValidate(source: string): ValidateResult {
  const errors: string[] = [];
  const warnings: string[] = [];

  if (!source.trim()) {
    errors.push('Empty source code');
    return { valid: false, message: 'Empty source code', errors, warnings };
  }

  // Check pragma
  if (!source.includes('pragma language_version')) {
    errors.push(
      'Missing pragma language_version declaration. Add: pragma language_version 0.20;'
    );
  } else {
    const pragmaMatch = source.match(
      /pragma\s+language_version\s+(\d+\.\d+)\s*;/
    );
    if (pragmaMatch) {
      const version = pragmaMatch[1];
      if (version !== '0.20') {
        warnings.push(
          `Language version ${version} specified. Current compatible version is 0.20.`
        );
      }
    } else {
      errors.push('Malformed pragma declaration');
    }
  }

  // Check for basic constructs
  const hasExport =
    source.includes('export ledger') ||
    source.includes('export circuit') ||
    source.includes('export witness');

  if (!hasExport) {
    warnings.push(
      'No exported declarations found. Contracts typically export at least one ledger, circuit, or witness.'
    );
  }

  // Check for unmatched braces
  const openBraces = (source.match(/{/g) || []).length;
  const closeBraces = (source.match(/}/g) || []).length;
  if (openBraces !== closeBraces) {
    errors.push(
      `Mismatched braces: ${openBraces} opening vs ${closeBraces} closing`
    );
  }

  // Check for unmatched parentheses
  const openParens = (source.match(/\(/g) || []).length;
  const closeParens = (source.match(/\)/g) || []).length;
  if (openParens !== closeParens) {
    errors.push(
      `Mismatched parentheses: ${openParens} opening vs ${closeParens} closing`
    );
  }

  const valid = errors.length === 0;
  const message = valid
    ? `Validation passed${warnings.length > 0 ? ` with ${warnings.length} warning(s)` : ''}`
    : `Validation failed with ${errors.length} error(s)`;

  return { valid, message, errors, warnings };
}

/**
 * Validate Compact source code using the compiler if available,
 * falling back to structural validation.
 */
export async function validateCompact(
  source: string,
  config: MidnightMCPConfig
): Promise<ValidateResult> {
  // First do structural validation
  const structural = structuralValidate(source);
  if (!structural.valid) {
    return structural;
  }

  // Try compiler-based validation
  const tempDir = join(tmpdir(), `compact-validate-${randomUUID()}`);
  const contractPath = join(tempDir, 'contract.compact');

  try {
    await mkdir(tempDir, { recursive: true });
    await writeFile(contractPath, source, 'utf-8');

    // Try compact compile with quick timeout for validation
    const command = `${config.compactBinaryPath} compile "${contractPath}" "${join(tempDir, 'out')}"`;

    await execAsync(command, {
      timeout: 30_000, // 30 second timeout for validation
      cwd: tempDir,
    });

    return {
      valid: true,
      message: 'Compact source code is valid (compiler verified)',
      errors: [],
      warnings: structural.warnings,
    };
  } catch (error) {
    const err = error as { stderr?: string; code?: string; message?: string };

    // If compiler not found, return structural result
    if (err.code === 'ENOENT' || err.message?.includes('not found')) {
      return {
        ...structural,
        message:
          structural.message + ' (structural only, compiler not available)',
      };
    }

    // Parse compiler errors
    const compilerErrors =
      err.stderr || err.message || 'Unknown compiler error';
    return {
      valid: false,
      message: 'Compact source code has compiler errors',
      errors: [compilerErrors],
      warnings: structural.warnings,
    };
  } finally {
    try {
      await rm(tempDir, { recursive: true, force: true });
    } catch {
      // Ignore cleanup errors
    }
  }
}
