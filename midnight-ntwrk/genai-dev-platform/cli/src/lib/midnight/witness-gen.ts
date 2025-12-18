/**
 * Auto-generate witness implementations for Compact contracts
 * 
 * Analyzes contract-info.json to determine witness requirements and
 * generates TypeScript implementations:
 * - Passthrough witnesses for circuits that don't modify private state
 * - No-op skeleton witnesses for circuits that do modify private state
 */

import * as fs from 'fs';
import * as path from 'path';
import { type WitnessInfo } from './types.js';

/**
 * Circuit information from contract-info.json
 */
interface CircuitInfo {
  name: string;
  parameters: Array<{ name: string; type: string }>;
  returnType?: string;
}

/**
 * Contract info structure from compactc output
 */
interface ContractInfo {
  name: string;
  circuits: Record<string, CircuitInfo>;
}

/**
 * Analyze a compiled contract to extract witness information
 * 
 * @param contractPath - Path to compiled contract directory
 * @returns Array of witness info objects
 */
export function analyzeContract(contractPath: string): WitnessInfo[] {
  const contractInfoPath = path.join(contractPath, 'compiler', 'contract-info.json');
  
  if (!fs.existsSync(contractInfoPath)) {
    throw new Error(
      `Contract info not found at ${contractInfoPath}. ` +
      'Make sure the contract is compiled with `midnightctl compile`.'
    );
  }
  
  const contractInfo: ContractInfo = JSON.parse(
    fs.readFileSync(contractInfoPath, 'utf-8')
  );
  
  const witnesses: WitnessInfo[] = [];
  
  for (const [circuitName, circuit] of Object.entries(contractInfo.circuits)) {
    // Heuristic: circuits with "private" in the name or that don't start with "get_"
    // likely modify private state
    const modifiesPrivateState = 
      circuitName.includes('private') ||
      (!circuitName.startsWith('get_') && !circuitName.startsWith('query_'));
    
    witnesses.push({
      name: circuitName,
      modifiesPrivateState,
      arguments: circuit.parameters || [],
      returnType: circuit.returnType,
    });
  }
  
  return witnesses;
}

/**
 * Generate witness TypeScript code
 * 
 * @param witnesses - Witness information from contract analysis
 * @param contractName - Name of the contract
 * @returns Generated TypeScript code
 */
export function generateWitnessCode(witnesses: WitnessInfo[], contractName: string): string {
  const lines: string[] = [];
  
  // Header
  lines.push('/**');
  lines.push(` * Auto-generated witnesses for ${contractName}`);
  lines.push(' * ');
  lines.push(` * Generated: ${new Date().toISOString()}`);
  lines.push(' * ');
  lines.push(' * Review these implementations and modify as needed.');
  lines.push(' * Witnesses that modify private state are marked with TODO comments.');
  lines.push(' */');
  lines.push('');
  lines.push('// Private state type - customize this based on your contract');
  lines.push('export type PrivateState = Record<string, unknown>;');
  lines.push('');
  lines.push('// Witness context passed to each witness function');
  lines.push('interface WitnessContext {');
  lines.push('  privateState: PrivateState;');
  lines.push('}');
  lines.push('');
  lines.push('// Witness result: [newPrivateState, publicOutputs]');
  lines.push('type WitnessResult = [PrivateState, unknown[]];');
  lines.push('');
  lines.push('export const witnesses = {');
  
  for (const witness of witnesses) {
    lines.push('');
    
    // Format arguments
    const args = witness.arguments
      .map(arg => `${arg.name}: ${formatType(arg.type)}`)
      .join(', ');
    
    const argNames = witness.arguments.map(arg => arg.name).join(', ');
    const argsComment = witness.arguments.length > 0 
      ? `// Arguments: ${witness.arguments.map(a => `${a.name} (${a.type})`).join(', ')}`
      : '// No arguments';
    
    if (witness.modifiesPrivateState) {
      // Generate no-op skeleton with TODO comment
      lines.push(`  // WARNING: Auto-generated no-op - review and implement`);
      lines.push(`  ${argsComment}`);
      lines.push(`  ${witness.name}: ({ privateState }${args ? `, ${args}` : ''}): WitnessResult => {`);
      lines.push(`    // TODO: Implement private state modification logic`);
      lines.push(`    // Current implementation: no-op (returns unchanged private state)`);
      lines.push(`    console.warn('Witness "${witness.name}" using auto-generated no-op implementation');`);
      lines.push(`    return [{ ...privateState }, []];`);
      lines.push(`  },`);
    } else {
      // Generate passthrough witness
      lines.push(`  // Passthrough witness (read-only circuit detected)`);
      lines.push(`  ${argsComment}`);
      lines.push(`  ${witness.name}: ({ privateState }${args ? `, ${args}` : ''}): WitnessResult => {`);
      lines.push(`    return [privateState, []];`);
      lines.push(`  },`);
    }
  }
  
  lines.push('};');
  lines.push('');
  lines.push('export default witnesses;');
  lines.push('');
  
  return lines.join('\n');
}

/**
 * Format a Compact type as a TypeScript type
 */
function formatType(compactType: string): string {
  // Simple type mapping
  const typeMap: Record<string, string> = {
    'Uint<64>': 'bigint',
    'Uint<32>': 'number',
    'Uint<8>': 'number',
    'Bool': 'boolean',
    'Bytes<32>': 'Uint8Array',
    'String': 'string',
  };
  
  return typeMap[compactType] || 'unknown';
}

/**
 * Generate and save witness file for a contract
 * 
 * @param contractPath - Path to compiled contract
 * @param outputDir - Directory to save witness file
 * @returns Path to generated witness file and analysis info
 */
export function generateWitnesses(
  contractPath: string,
  outputDir: string
): { 
  witnessPath: string; 
  witnesses: WitnessInfo[];
  contractName: string;
} {
  // Analyze contract
  const witnesses = analyzeContract(contractPath);
  
  // Get contract name from path
  const contractName = path.basename(contractPath);
  
  // Generate code
  const code = generateWitnessCode(witnesses, contractName);
  
  // Ensure output directory exists
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }
  
  // Write witness file
  const witnessPath = path.join(outputDir, 'witnesses.ts');
  fs.writeFileSync(witnessPath, code, 'utf-8');
  
  return { witnessPath, witnesses, contractName };
}

/**
 * Load existing witness implementation
 * 
 * @param witnessPath - Path to witness file
 * @returns Witness object or null if not found
 */
export async function loadWitnesses(witnessPath: string): Promise<any | null> {
  if (!fs.existsSync(witnessPath)) {
    return null;
  }
  
  try {
    // Dynamic import of TypeScript file
    // Note: This requires ts-node or transpilation
    const module = await import(witnessPath);
    return module.witnesses || module.default;
  } catch (error) {
    console.warn(`Failed to load witnesses from ${witnessPath}: ${(error as Error).message}`);
    return null;
  }
}

/**
 * Get summary of witness generation results
 */
export function getWitnessSummary(witnesses: WitnessInfo[]): {
  total: number;
  passthrough: number;
  needsImplementation: number;
} {
  const passthrough = witnesses.filter(w => !w.modifiesPrivateState).length;
  return {
    total: witnesses.length,
    passthrough,
    needsImplementation: witnesses.length - passthrough,
  };
}
