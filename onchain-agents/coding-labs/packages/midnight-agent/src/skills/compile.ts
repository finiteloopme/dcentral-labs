/**
 * Compile Compact Contract Skill
 *
 * Compiles Compact smart contract source code to ZK circuits
 * by calling the compact_compile MCP tool via HTTP.
 */

import type { Message } from '@a2a-js/sdk';
import type { SkillEvent, SessionContext, Artifact } from './index.js';
import { extractTextFromMessage } from './index.js';
import { getMCPClient } from '../mcp-client.js';

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
 * Extract contract name from Compact source code.
 * Looks for `contract ContractName { ... }` pattern.
 */
function extractContractName(source: string): string {
  const match = source.match(/contract\s+(\w+)\s*\{/);
  return match ? match[1] : 'contract';
}

/**
 * Compile Compact source code via MCP
 */
export async function* compileCompact(
  message: Message,
  _session?: SessionContext
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

  yield { type: 'status', message: 'Connecting to MCP server...' };

  const mcp = getMCPClient();

  // Notify user about expected compilation time
  // Full compilation includes ZK key generation which can take several minutes
  yield {
    type: 'status',
    message:
      'Starting Compact contract compilation with ZK proof key generation. ' +
      'This process typically takes 2-5 minutes depending on contract complexity. ' +
      "I'll notify you when it's complete.",
  };

  yield { type: 'status', message: 'Compiling Compact contract via MCP...' };

  try {
    const result = await mcp.compileCompact(compactCode);

    if (!result.success) {
      yield {
        type: 'artifact',
        name: 'compile-error.txt',
        content: result.errors || result.message,
        mimeType: 'text/plain',
      };

      yield {
        type: 'error',
        message: `Compilation failed: ${result.message}`,
      };
      return;
    }

    yield { type: 'status', message: 'Compilation successful!' };

    // Extract contract name for session context
    const contractName = extractContractName(compactCode);

    // Emit artifacts
    for (const artifact of result.artifacts) {
      yield {
        type: 'artifact',
        name: artifact.filename,
        content: artifact.content,
        mimeType: artifact.filename.endsWith('.json')
          ? 'application/json'
          : 'text/javascript',
      };
    }

    // Emit session update with artifacts (not path)
    yield {
      type: 'session-update',
      context: {
        artifacts: result.artifacts as Artifact[],
        contractName,
      },
    };

    yield {
      type: 'result',
      data: {
        success: true,
        message: 'Contract compiled successfully',
        contractName,
        artifactCount: result.artifacts.length,
      },
      message: `Compact contract "${contractName}" compiled successfully. Ready for deployment.`,
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error';

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
}
