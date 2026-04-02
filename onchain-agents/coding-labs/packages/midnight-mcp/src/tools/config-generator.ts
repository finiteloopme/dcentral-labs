/**
 * Contract Config Generator
 *
 * Generates contract.config.ts files from compiled Compact contract artifacts.
 * This config is required by the toolkit's generate-intent command.
 *
 * The generator:
 * 1. Parses compiled contract to extract witness function names
 * 2. Infers initial private state from witness patterns
 * 3. Generates witness implementations (smart defaults or no-ops)
 * 4. Outputs a TypeScript config file compatible with toolkit-js
 */

import { readFile, writeFile, readdir } from 'fs/promises';
import { join, basename } from 'path';

// -----------------------------------------------------------------------------
// Types
// -----------------------------------------------------------------------------

export interface GenerateConfigParams {
  /** Name of the contract (e.g., 'counter') */
  contractName: string;
  /** Path to compiled contract directory (contains managed/<name>/) */
  compiledDir: string;
  /** Where to write the generated contract.config.ts */
  outputPath: string;
  /** Optional: override inferred initial private state */
  initialPrivateState?: Record<string, unknown>;
}

export interface GeneratedConfig {
  /** Path to the generated config file */
  configPath: string;
  /** Inferred private state type as string */
  privateStateType: string;
  /** List of witness function names found */
  witnessNames: string[];
  /** Initial private state that will be used */
  initialPrivateState: Record<string, unknown>;
}

// -----------------------------------------------------------------------------
// Contract Info Types (from contract-info.json)
// -----------------------------------------------------------------------------

interface WitnessArg {
  name: string;
  type: { 'type-name': string; maxval?: number };
}

interface ContractInfo {
  circuits: Array<{ name: string; pure: boolean; arguments: WitnessArg[] }>;
  witnesses: Array<{ name: string; arguments: WitnessArg[] }>;
  contracts: unknown[];
}

/**
 * Parse contract-info.json from compiled output.
 * This is the authoritative source for witness information.
 */
async function parseContractInfo(
  compiledDir: string
): Promise<ContractInfo | null> {
  const contractInfoPath = join(compiledDir, 'compiler', 'contract-info.json');
  try {
    const content = await readFile(contractInfoPath, 'utf-8');
    return JSON.parse(content) as ContractInfo;
  } catch {
    console.warn(
      `[config-generator] contract-info.json not found at ${contractInfoPath}`
    );
    return null;
  }
}

// -----------------------------------------------------------------------------
// Witness Pattern Detection
// -----------------------------------------------------------------------------

/**
 * Known witness patterns and their implementations.
 */
const WITNESS_PATTERNS: Record<
  string,
  {
    stateFields: Record<string, unknown>;
    implementation: (witnessName: string) => string;
  }
> = {
  // Counter pattern: increment, decrement, reset
  increment: {
    stateFields: { count: 0 },
    implementation: () =>
      `({ privateState }, amount) => [{ ...privateState, count: (privateState.count || 0) + Number(amount) }, []]`,
  },
  decrement: {
    stateFields: { count: 0 },
    implementation: () =>
      `({ privateState }, amount) => [{ ...privateState, count: Math.max(0, (privateState.count || 0) - Number(amount)) }, []]`,
  },
  reset: {
    stateFields: { count: 0 },
    implementation: () => `() => [{ count: 0 }, []]`,
  },
  // Balance pattern
  balance: {
    stateFields: { balance: 0 },
    implementation: () => `({ privateState }, ...args) => [privateState, []]`,
  },
  // Set/get pattern
  set: {
    stateFields: { value: null },
    implementation: () =>
      `({ privateState }, value) => [{ ...privateState, value }, []]`,
  },
  get: {
    stateFields: { value: null },
    implementation: () => `({ privateState }) => [privateState, []]`,
  },
};

/**
 * Strip common witness prefixes for pattern matching.
 * Witnesses are typically named private_xxx or witness_xxx in Compact.
 */
function stripWitnessPrefix(name: string): string {
  return name.toLowerCase().replace(/^(private_|witness_)/, '');
}

/**
 * Infer initial private state from witness function names.
 */
function inferInitialPrivateState(
  witnessNames: string[]
): Record<string, unknown> {
  const state: Record<string, unknown> = {};

  for (const witnessName of witnessNames) {
    // Strip common prefixes before pattern matching
    const baseName = stripWitnessPrefix(witnessName);

    for (const [pattern, config] of Object.entries(WITNESS_PATTERNS)) {
      if (baseName.includes(pattern)) {
        Object.assign(state, config.stateFields);
      }
    }
  }

  // If no patterns matched, return empty state
  return Object.keys(state).length > 0 ? state : {};
}

/**
 * Generate witness function implementation for a given witness name.
 */
function generateWitnessImplementation(witnessName: string): string {
  // Strip common prefixes for pattern matching
  const baseName = stripWitnessPrefix(witnessName);

  // Check for known patterns
  for (const [pattern, config] of Object.entries(WITNESS_PATTERNS)) {
    if (baseName.includes(pattern)) {
      return config.implementation(witnessName);
    }
  }

  // Default: preserve state, ignore args
  return `({ privateState }, ...args) => [privateState, []]`;
}

// -----------------------------------------------------------------------------
// Contract Parsing
// -----------------------------------------------------------------------------

/**
 * Extract witness function names from compiled contract.
 *
 * Primary source: contract-info.json (authoritative, generated by compactc)
 * Fallback: regex patterns on compiled JS (legacy, less reliable)
 */
async function extractWitnessNames(compiledDir: string): Promise<string[]> {
  // Try contract-info.json first (authoritative source)
  const contractInfo = await parseContractInfo(compiledDir);
  if (contractInfo?.witnesses && contractInfo.witnesses.length > 0) {
    const names = contractInfo.witnesses.map((w) => w.name);
    console.log(
      `[config-generator] Found ${names.length} witness(es) from contract-info.json:`,
      names
    );
    return names;
  }

  // Fall back to regex patterns (legacy - less reliable)
  console.warn(
    `[config-generator] contract-info.json not found or has no witnesses, falling back to regex`
  );

  const contractDir = join(compiledDir, 'contract');
  const witnesses: string[] = [];

  try {
    // Try to read the contract module
    const indexPath = join(contractDir, 'index.cjs');
    let content: string;

    try {
      content = await readFile(indexPath, 'utf-8');
    } catch {
      // Try .js extension
      const jsPath = join(contractDir, 'index.js');
      content = await readFile(jsPath, 'utf-8');
    }

    // Look for witness function patterns in the compiled JS
    // Pattern 1: witness declarations in Contract class
    const witnessRegex = /witness[_\s]+(\w+)/gi;
    let match;
    while ((match = witnessRegex.exec(content)) !== null) {
      const name = match[1];
      if (name && !witnesses.includes(name)) {
        witnesses.push(name);
      }
    }

    // Pattern 2: Look for private_ prefix functions (common convention)
    const privateRegex = /["']?(private_\w+)["']?\s*:/gi;
    while ((match = privateRegex.exec(content)) !== null) {
      const name = match[1];
      if (name && !witnesses.includes(name)) {
        witnesses.push(name);
      }
    }

    // Pattern 3: Check ZKIR files for witness circuits
    const zkirDir = join(compiledDir, 'zkir');
    try {
      const zkirFiles = await readdir(zkirDir);
      for (const file of zkirFiles) {
        if (file.endsWith('.zkir')) {
          const circuitName = basename(file, '.zkir');
          // Witnesses typically have 'witness' or 'private' prefix
          if (
            circuitName.startsWith('witness_') ||
            circuitName.startsWith('private_')
          ) {
            if (!witnesses.includes(circuitName)) {
              witnesses.push(circuitName);
            }
          }
        }
      }
    } catch {
      // ZKIR directory may not exist
    }
  } catch (error) {
    console.warn(
      `[config-generator] Could not parse contract for witnesses:`,
      error
    );
  }

  return witnesses;
}

// NOTE: getContractNameFromInfo was removed as unused.
// Contract name is passed explicitly via params.

// -----------------------------------------------------------------------------
// Config Generation
// -----------------------------------------------------------------------------

/**
 * Generate TypeScript type definition for private state.
 */
function generatePrivateStateType(
  state: Record<string, unknown>,
  hasWitnesses: boolean
): string {
  // For contracts without witnesses, use empty object type
  if (!hasWitnesses || Object.keys(state).length === 0) {
    return '{}';
  }

  const fields = Object.entries(state)
    .map(([key, value]) => {
      let type = 'unknown';
      if (typeof value === 'number') type = 'number';
      else if (typeof value === 'bigint') type = 'bigint';
      else if (typeof value === 'string') type = 'string';
      else if (typeof value === 'boolean') type = 'boolean';
      else if (value === null) type = 'unknown';
      return `  ${key}: ${type};`;
    })
    .join('\n');

  return `{\n${fields}\n}`;
}

/**
 * Generate the contract.config.ts file content.
 */
function generateConfigContent(
  contractName: string,
  managedPath: string,
  witnessNames: string[],
  initialPrivateState: Record<string, unknown>
): string {
  const hasWitnesses = witnessNames.length > 0;
  const privateStateType = generatePrivateStateType(
    initialPrivateState,
    hasWitnesses
  );
  const pascalName =
    contractName.charAt(0).toUpperCase() + contractName.slice(1) + 'Contract';

  // Generate witness implementations only if there are witnesses
  const witnessEntries = witnessNames
    .map((name) => {
      const impl = generateWitnessImplementation(name);
      return `  ${name}: ${impl}`;
    })
    .join(',\n');

  // Generate initial state as JSON
  const initialStateJson = JSON.stringify(
    hasWitnesses ? initialPrivateState : {},
    null,
    2
  )
    .split('\n')
    .map((line, i) => (i === 0 ? line : '  ' + line))
    .join('\n');

  // For contracts without witnesses, use withVacantWitnesses
  // For contracts with witnesses, use withWitnesses(witnesses)
  const witnessesSection = hasWitnesses
    ? `
/**
 * Witness function implementations.
 * These handle private state updates during circuit execution.
 */
const witnesses: Contract.Contract.Witnesses<${pascalName}> = {
${witnessEntries}
};
`
    : '';

  const witnessBinding = hasWitnesses
    ? `CompiledContract.withWitnesses(witnesses)`
    : `CompiledContract.withVacantWitnesses`;

  return `/**
 * Auto-generated contract configuration for ${contractName}
 * Generated by midnight-mcp config-generator
 *
 * This file is used by the toolkit's generate-intent command.
 */

import { CompiledContract, ContractExecutable${hasWitnesses ? ', type Contract' : ''} } from '@midnight-ntwrk/compact-js/effect';
import { Contract as C_ } from '${managedPath}/contract/index.js';

/**
 * Private state type for this contract.
 */
type PrivateState = ${privateStateType};

// Type alias binding the contract to our private state type
type ${pascalName} = C_<PrivateState>;
const ${pascalName} = C_;
${witnessesSection}
/**
 * Creates the initial private state for new contract instances.
 */
const createInitialPrivateState = (): PrivateState => (${initialStateJson});

export default {
  contractExecutable: CompiledContract.make<${pascalName}>('${pascalName}', ${pascalName}).pipe(
    ${witnessBinding},
    CompiledContract.withCompiledFileAssets('${managedPath}'),
    ContractExecutable.make
  ),
  createInitialPrivateState,
  config: {
    network: 'undeployed'
  }
};
`;
}

// -----------------------------------------------------------------------------
// Main Export
// -----------------------------------------------------------------------------

/**
 * Generate a contract.config.ts file from compiled contract artifacts.
 *
 * @param params - Generation parameters
 * @returns Information about the generated config
 */
export async function generateContractConfig(
  params: GenerateConfigParams
): Promise<GeneratedConfig> {
  const { contractName, compiledDir, outputPath, initialPrivateState } = params;

  // Extract witness names from compiled contract
  const witnessNames = await extractWitnessNames(compiledDir);
  console.log(
    `[config-generator] Found ${witnessNames.length} witness(es):`,
    witnessNames
  );

  // Infer or use provided initial private state
  const inferredState = inferInitialPrivateState(witnessNames);
  const finalPrivateState = initialPrivateState ?? inferredState;
  console.log(`[config-generator] Initial private state:`, finalPrivateState);

  // Get the managed path relative to config location
  // Config will be written to same directory as managed/
  const managedPath = `./managed/${contractName}`;

  // Generate config content
  const configContent = generateConfigContent(
    contractName,
    managedPath,
    witnessNames,
    finalPrivateState
  );

  // Write config file
  await writeFile(outputPath, configContent, 'utf-8');
  console.log(`[config-generator] Generated config at: ${outputPath}`);

  return {
    configPath: outputPath,
    privateStateType: generatePrivateStateType(
      finalPrivateState,
      witnessNames.length > 0
    ),
    witnessNames,
    initialPrivateState: finalPrivateState,
  };
}
