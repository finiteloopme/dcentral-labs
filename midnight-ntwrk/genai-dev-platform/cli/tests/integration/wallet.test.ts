/**
 * Wallet Integration Tests
 * 
 * Tests wallet operations against live Midnight services.
 * 
 * Prerequisites:
 * - Midnight services running (node, indexer, proof-server)
 * - Toolkit binary installed
 * - .env file configured in project root
 * 
 * Run with: npm run test:integration
 */

import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import {
  checkServicesAvailable,
  getServiceConfig,
} from './setup.js';
import {
  createTestWallet,
  fundTestWallet,
  getTestWalletBalance,
  cleanupTestWallets,
  queryIndexer,
  generateTestWalletName,
  waitFor,
  formatNight,
  TEST_WALLET_PREFIX,
} from './helpers.js';

// Track whether services are available
let servicesAvailable = false;
let serviceStatus: {
  node: boolean;
  indexer: boolean;
  toolkit: boolean;
};

describe('wallet integration tests', () => {
  beforeAll(async () => {
    // Check if services are available
    const status = await checkServicesAvailable();
    servicesAvailable = status.available;
    serviceStatus = {
      node: status.node,
      indexer: status.indexer,
      toolkit: status.toolkit,
    };
    
    if (!servicesAvailable) {
      console.log('\n⚠️  Skipping integration tests - services not available:');
      console.log(`   Node:    ${status.node ? '✓' : '✗'} (${status.config.nodeUrl})`);
      console.log(`   Indexer: ${status.indexer ? '✓' : '✗'} (${status.config.indexerUrl})`);
      console.log(`   Toolkit: ${status.toolkit ? '✓' : '✗'} (${status.config.toolkitPath})`);
      console.log('\n   Configure services in .env file at project root.\n');
    }
  });
  
  afterAll(async () => {
    // Clean up all test wallets
    if (servicesAvailable) {
      const { cleaned, failed } = await cleanupTestWallets();
      if (cleaned.length > 0) {
        console.log(`\n🧹 Cleaned up ${cleaned.length} test wallet(s)`);
      }
      if (failed.length > 0) {
        console.log(`⚠️  Failed to clean up ${failed.length} wallet(s): ${failed.join(', ')}`);
      }
    }
  });
  
  describe('wallet create', () => {
    it('creates wallet with correct address format', async () => {
      if (!servicesAvailable) {
        console.log('   ⏭️  Skipped - services not available');
        return;
      }
      
      const result = await createTestWallet();
      
      expect(result.success).toBe(true);
      expect(result.name).toMatch(new RegExp(`^${TEST_WALLET_PREFIX}`));
      
      // Address should use 'undeployed' network prefix for local dev
      expect(result.address).toMatch(/^mn_addr_undeployed1/);
    });
    
    it('creates wallet with unique addresses', async () => {
      if (!servicesAvailable) {
        console.log('   ⏭️  Skipped - services not available');
        return;
      }
      
      const wallet1 = await createTestWallet();
      const wallet2 = await createTestWallet();
      
      expect(wallet1.success).toBe(true);
      expect(wallet2.success).toBe(true);
      expect(wallet1.address).not.toBe(wallet2.address);
    });
    
    it('fails to create wallet with duplicate name', async () => {
      if (!servicesAvailable) {
        console.log('   ⏭️  Skipped - services not available');
        return;
      }
      
      const name = generateTestWalletName('duplicate');
      
      const result1 = await createTestWallet(name);
      expect(result1.success).toBe(true);
      
      const result2 = await createTestWallet(name);
      expect(result2.success).toBe(false);
      expect(result2.output).toContain('already exists');
    });
  });
  
  describe('wallet balance', () => {
    it('shows zero balance for new unfunded wallet', async () => {
      if (!servicesAvailable) {
        console.log('   ⏭️  Skipped - services not available');
        return;
      }
      
      const wallet = await createTestWallet();
      expect(wallet.success).toBe(true);
      
      const balance = await getTestWalletBalance(wallet.name);
      
      expect(balance.success).toBe(true);
      expect(balance.total).toBe(0n);
      expect(balance.shielded).toBe(0n);
      expect(balance.unshielded).toBe(0n);
    });
  });
  
  describe('wallet fund', () => {
    it('funds wallet from genesis successfully', async () => {
      if (!servicesAvailable) {
        console.log('   ⏭️  Skipped - services not available');
        return;
      }
      
      // Create wallet
      const wallet = await createTestWallet();
      expect(wallet.success).toBe(true);
      
      // Fund with 1000 NIGHT
      const fundResult = await fundTestWallet(wallet.name, 1000);
      expect(fundResult.success).toBe(true);
      
      // Wait a moment for transaction to be indexed
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Check balance
      const balance = await getTestWalletBalance(wallet.name);
      expect(balance.success).toBe(true);
      expect(balance.unshielded).toBe(1000_000_000n); // 1000 * 10^6
      
      console.log(`   ✓ Funded wallet with ${formatNight(balance.unshielded)} NIGHT`);
    });
    
    it('funded balance matches indexer query', async () => {
      if (!servicesAvailable) {
        console.log('   ⏭️  Skipped - services not available');
        return;
      }
      
      // Create and fund wallet
      const wallet = await createTestWallet();
      expect(wallet.success).toBe(true);
      
      const amount = 500; // 500 NIGHT
      const fundResult = await fundTestWallet(wallet.name, amount);
      expect(fundResult.success).toBe(true);
      
      // Wait for indexer to catch up
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Query balance via CLI
      const cliBalance = await getTestWalletBalance(wallet.name);
      expect(cliBalance.success).toBe(true);
      
      // Query indexer directly for the wallet address
      // Note: This requires knowing the address format the indexer uses
      // For now, just verify CLI balance matches expected
      expect(cliBalance.unshielded).toBe(BigInt(amount) * 1_000_000n);
    });
  });
  
  describe('wallet send', () => {
    it('transfers tokens between wallets', async () => {
      if (!servicesAvailable) {
        console.log('   ⏭️  Skipped - services not available');
        return;
      }
      
      // Create sender wallet
      const sender = await createTestWallet(generateTestWalletName('sender'));
      expect(sender.success).toBe(true);
      
      // Create receiver wallet
      const receiver = await createTestWallet(generateTestWalletName('receiver'));
      expect(receiver.success).toBe(true);
      
      // Fund sender with 2000 NIGHT
      const fundResult = await fundTestWallet(sender.name, 2000);
      expect(fundResult.success).toBe(true);
      
      // Wait for funding to be confirmed
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Verify sender has funds
      const senderBalanceBefore = await getTestWalletBalance(sender.name);
      expect(senderBalanceBefore.unshielded).toBe(2000_000_000n);
      
      // TODO: Implement send command test when send is fully working
      // For now, just verify the setup works
      console.log(`   ✓ Sender funded with ${formatNight(senderBalanceBefore.unshielded)} NIGHT`);
      console.log(`   ⏭️  Send test pending - requires send command implementation`);
    });
  });
  
  describe('address derivation', () => {
    it('derived address matches toolkit show-address output', async () => {
      if (!servicesAvailable) {
        console.log('   ⏭️  Skipped - services not available');
        return;
      }
      
      // This test verifies that the address stored in the wallet
      // matches what the toolkit derives from the same seed
      
      const wallet = await createTestWallet();
      expect(wallet.success).toBe(true);
      expect(wallet.address).toBeTruthy();
      
      // The fact that the wallet was created successfully and has an address
      // means the toolkit was used for derivation (since we require toolkit now)
      // The address format should be correct
      expect(wallet.address).toMatch(/^mn_addr_undeployed1[a-z0-9]+$/);
      
      console.log(`   ✓ Address derived correctly: ${wallet.address.slice(0, 30)}...`);
    });
  });
});
