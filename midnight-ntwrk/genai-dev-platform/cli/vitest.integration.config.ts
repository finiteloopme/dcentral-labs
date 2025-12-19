import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Only run integration tests
    include: ['tests/integration/**/*.test.ts'],
    
    // Long timeouts for blockchain operations
    testTimeout: 120000,  // 2 minutes for individual tests
    hookTimeout: 60000,   // 1 minute for setup/teardown
    
    // Run tests sequentially (they depend on chain state)
    sequence: {
      concurrent: false,
    },
    
    // Enable global test functions (describe, it, expect)
    globals: true,
    
    // Disable watch mode by default for integration tests
    watch: false,
    
    // Reporter configuration
    reporters: ['verbose'],
    
    // Environment
    environment: 'node',
  },
});
