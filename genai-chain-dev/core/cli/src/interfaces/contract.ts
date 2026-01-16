/**
 * Contract adapter interface - implemented by chain-specific contract handlers
 */

/**
 * Compile result
 */
export interface CompileResult {
  /** Whether compilation succeeded */
  success: boolean;
  /** Compiled artifacts */
  artifacts: ArtifactInfo[];
  /** Compiler warnings */
  warnings: string[];
  /** Compiler errors (if failed) */
  errors: string[];
  /** Time taken in ms */
  duration: number;
}

/**
 * Artifact information
 */
export interface ArtifactInfo {
  /** Contract name */
  name: string;
  /** Source file path */
  sourcePath: string;
  /** Output artifact path */
  artifactPath: string;
  /** Bytecode size in bytes */
  bytecodeSize?: number;
}

/**
 * Compile options
 */
export interface CompileOptions {
  /** Optimization enabled */
  optimize?: boolean;
  /** Optimizer runs */
  optimizerRuns?: number;
  /** Specific contracts to compile */
  contracts?: string[];
  /** Additional compiler arguments */
  args?: string[];
}

/**
 * Deploy result
 */
export interface DeployResult {
  /** Deployed contract address */
  address: string;
  /** Transaction hash */
  transactionHash: string;
  /** Block number */
  blockNumber: number;
  /** Gas used */
  gasUsed: string;
  /** Explorer URL */
  explorerUrl?: string;
}

/**
 * Deploy options
 */
export interface DeployOptions {
  /** Network to deploy to */
  network?: string;
  /** Private key (if not using default wallet) */
  privateKey?: string;
  /** Gas limit override */
  gasLimit?: bigint;
  /** Verify contract after deployment */
  verify?: boolean;
  /** Additional arguments passed to deployment script */
  args?: string[];
}

/**
 * Verify result
 */
export interface VerifyResult {
  /** Whether verification succeeded */
  success: boolean;
  /** Verification status message */
  message: string;
  /** Explorer URL to verified contract */
  explorerUrl?: string;
}

/**
 * Contract adapter interface
 */
export interface ContractAdapter {
  /**
   * Compile contracts
   * @param options - Compile options
   */
  compile(options?: CompileOptions): Promise<CompileResult>;
  
  /**
   * Deploy a contract
   * @param contract - Contract name or script path
   * @param constructorArgs - Constructor arguments
   * @param options - Deploy options
   */
  deploy(
    contract: string,
    constructorArgs?: unknown[],
    options?: DeployOptions
  ): Promise<DeployResult>;
  
  /**
   * Verify a deployed contract on block explorer
   * @param address - Contract address
   * @param contract - Contract name or source path
   */
  verify?(address: string, contract: string): Promise<VerifyResult>;
  
  /**
   * Run tests
   * @param filter - Test filter pattern
   * @param options - Additional options
   */
  test?(filter?: string, options?: TestOptions): Promise<TestResult>;
}

/**
 * Test options
 */
export interface TestOptions {
  /** Verbosity level */
  verbosity?: number;
  /** Run with gas reporting */
  gasReport?: boolean;
  /** Specific test file or pattern */
  match?: string;
}

/**
 * Test result
 */
export interface TestResult {
  /** Whether all tests passed */
  success: boolean;
  /** Number of tests passed */
  passed: number;
  /** Number of tests failed */
  failed: number;
  /** Number of tests skipped */
  skipped: number;
  /** Time taken in ms */
  duration: number;
}
