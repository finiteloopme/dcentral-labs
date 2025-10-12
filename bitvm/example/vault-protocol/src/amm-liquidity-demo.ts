#!/usr/bin/env node

/**
 * BitVM3 AMM Liquidity Demo
 * 
 * Demonstrates how the trustless vault provides liquidity to a simple AMM pool
 * on an EVM chain. The AMM uses a constant product formula (x * y = k).
 */

import axios from 'axios';
import chalk from 'chalk';

// Simple AMM implementation (Uniswap V2 style)
class SimpleAMM {
  private reserveA: number;  // WBTC reserves
  private reserveB: number;  // USDT reserves
  private totalShares: number;  // LP tokens
  private constant: number;  // k = x * y
  
  constructor() {
    this.reserveA = 0;
    this.reserveB = 0;
    this.totalShares = 0;
    this.constant = 0;
  }
  
  // Initialize pool with first liquidity
  initializePool(amountA: number, amountB: number): number {
    if (this.totalShares > 0) {
      throw new Error("Pool already initialized");
    }
    
    this.reserveA = amountA;
    this.reserveB = amountB;
    this.constant = amountA * amountB;
    
    // Initial shares = sqrt(amountA * amountB)
    this.totalShares = Math.sqrt(this.constant);
    
    return this.totalShares;
  }
  
  // Add liquidity maintaining current ratio
  addLiquidity(amountA: number): { amountB: number, shares: number } {
    if (this.totalShares === 0) {
      throw new Error("Pool not initialized");
    }
    
    // Calculate required amountB to maintain ratio
    const amountB = (amountA * this.reserveB) / this.reserveA;
    
    // Calculate LP shares to mint
    const shares = (amountA * this.totalShares) / this.reserveA;
    
    // Update reserves
    this.reserveA += amountA;
    this.reserveB += amountB;
    this.totalShares += shares;
    this.constant = this.reserveA * this.reserveB;
    
    return { amountB, shares };
  }
  
  // Remove liquidity
  removeLiquidity(shares: number): { amountA: number, amountB: number } {
    const shareRatio = shares / this.totalShares;
    
    const amountA = this.reserveA * shareRatio;
    const amountB = this.reserveB * shareRatio;
    
    // Update reserves
    this.reserveA -= amountA;
    this.reserveB -= amountB;
    this.totalShares -= shares;
    this.constant = this.reserveA * this.reserveB;
    
    return { amountA, amountB };
  }
  
  // Swap tokenA for tokenB
  swapAForB(amountAIn: number): number {
    const amountAInWithFee = amountAIn * 997; // 0.3% fee
    const numerator = amountAInWithFee * this.reserveB;
    const denominator = (this.reserveA * 1000) + amountAInWithFee;
    const amountBOut = numerator / denominator;
    
    // Update reserves
    this.reserveA += amountAIn;
    this.reserveB -= amountBOut;
    
    return amountBOut;
  }
  
  // Get current price
  getPrice(): { priceAInB: number, priceBInA: number } {
    return {
      priceAInB: this.reserveB / this.reserveA,
      priceBInA: this.reserveA / this.reserveB
    };
  }
  
  // Calculate impermanent loss
  calculateImpermanentLoss(initialPriceRatio: number): number {
    const currentPriceRatio = this.reserveB / this.reserveA;
    const priceChange = currentPriceRatio / initialPriceRatio;
    
    // IL = 2 * sqrt(priceChange) / (1 + priceChange) - 1
    const il = (2 * Math.sqrt(priceChange)) / (1 + priceChange) - 1;
    return il * 100; // Return as percentage
  }
  
  getPoolState() {
    return {
      reserveA: this.reserveA,
      reserveB: this.reserveB,
      totalShares: this.totalShares,
      constant: this.constant,
      price: this.getPrice()
    };
  }
}

// BitVM3 Vault with AMM integration
class BitVM3AMMVault {
  private amm: SimpleAMM;
  private vaultBTC: number;
  private vaultUSDT: number;
  private lpShares: Map<string, number>;
  private bridgedBTC: number;  // BTC bridged to EVM as WBTC
  
  constructor() {
    this.amm = new SimpleAMM();
    this.vaultBTC = 0;
    this.vaultUSDT = 0;
    this.lpShares = new Map();
    this.bridgedBTC = 0;
  }
  
  // Deposit to vault
  async depositToVault(user: string, amountBTC: number, amountUSDT: number) {
    console.log(chalk.blue(`\n💰 ${user} depositing ${amountBTC} BTC and ${amountUSDT} USDT to vault`));
    
    this.vaultBTC += amountBTC;
    this.vaultUSDT += amountUSDT;
    
    // Generate proof of deposit (simplified)
    const proof = await this.generateDepositProof(user, amountBTC, amountUSDT);
    console.log(chalk.gray(`   Proof: ${proof.substring(0, 16)}...`));
    
    return proof;
  }
  
  // Bridge BTC to EVM chain
  async bridgeToEVM(amountBTC: number) {
    console.log(chalk.yellow(`\n🌉 Bridging ${amountBTC} BTC to EVM chain as WBTC`));
    
    if (amountBTC > this.vaultBTC) {
      throw new Error("Insufficient BTC in vault");
    }
    
    // Simulate bridge delay
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    this.vaultBTC -= amountBTC;
    this.bridgedBTC += amountBTC;
    
    console.log(chalk.green(`   ✅ Bridged successfully`));
    console.log(chalk.gray(`   Vault BTC: ${this.vaultBTC}, Bridged WBTC: ${this.bridgedBTC}`));
    
    return this.bridgedBTC;
  }
  
  // Deploy liquidity to AMM
  async deployToAMM(wbtcAmount: number, usdtAmount: number) {
    console.log(chalk.cyan(`\n🏊 Deploying liquidity to AMM pool`));
    console.log(chalk.gray(`   WBTC: ${wbtcAmount}, USDT: ${usdtAmount}`));
    
    if (wbtcAmount > this.bridgedBTC) {
      throw new Error("Insufficient bridged WBTC");
    }
    if (usdtAmount > this.vaultUSDT) {
      throw new Error("Insufficient USDT");
    }
    
    let shares: number;
    
    // Initialize or add to pool
    if (this.amm.getPoolState().totalShares === 0) {
      shares = this.amm.initializePool(wbtcAmount, usdtAmount);
      console.log(chalk.green(`   ✅ Pool initialized with ${shares.toFixed(4)} LP tokens`));
    } else {
      const result = this.amm.addLiquidity(wbtcAmount);
      if (result.amountB > usdtAmount) {
        throw new Error(`Need ${result.amountB} USDT, only have ${usdtAmount}`);
      }
      shares = result.shares;
      usdtAmount = result.amountB;
      console.log(chalk.green(`   ✅ Added liquidity, received ${shares.toFixed(4)} LP tokens`));
    }
    
    // Update vault state
    this.bridgedBTC -= wbtcAmount;
    this.vaultUSDT -= usdtAmount;
    
    // Track LP shares (simplified - in practice, track per user)
    this.lpShares.set("vault", (this.lpShares.get("vault") || 0) + shares);
    
    // Display pool state
    const poolState = this.amm.getPoolState();
    console.log(chalk.gray(`   Pool: ${poolState.reserveA.toFixed(4)} WBTC / ${poolState.reserveB.toFixed(2)} USDT`));
    console.log(chalk.gray(`   Price: 1 WBTC = ${poolState.price.priceAInB.toFixed(2)} USDT`));
    
    return shares;
  }
  
  // Simulate trading activity
  async simulateTrading(numTrades: number) {
    console.log(chalk.magenta(`\n📊 Simulating ${numTrades} trades on AMM`));
    
    const initialPrice = this.amm.getPrice().priceAInB;
    
    for (let i = 0; i < numTrades; i++) {
      // Random trade direction and size
      const isBuy = Math.random() > 0.5;
      const tradeSize = Math.random() * 0.01; // Up to 0.01 WBTC
      
      if (isBuy) {
        const amountOut = this.amm.swapAForB(tradeSize);
        console.log(chalk.gray(`   Trade ${i+1}: Buy ${tradeSize.toFixed(6)} WBTC → ${amountOut.toFixed(2)} USDT`));
      } else {
        // For simplicity, we only implement A->B swaps
        // In real implementation, would have B->A as well
      }
    }
    
    const finalPrice = this.amm.getPrice().priceAInB;
    const priceChange = ((finalPrice - initialPrice) / initialPrice) * 100;
    
    console.log(chalk.yellow(`   Price impact: ${priceChange > 0 ? '+' : ''}${priceChange.toFixed(2)}%`));
    console.log(chalk.gray(`   New price: 1 WBTC = ${finalPrice.toFixed(2)} USDT`));
    
    // Calculate fees earned (0.3% of volume)
    const feesEarned = numTrades * 0.01 * 0.003 * finalPrice;
    console.log(chalk.green(`   Fees earned: ~${feesEarned.toFixed(2)} USDT`));
  }
  
  // Withdraw liquidity
  async withdrawFromAMM(sharePercent: number) {
    console.log(chalk.red(`\n🏦 Withdrawing ${sharePercent}% of liquidity from AMM`));
    
    const vaultShares = this.lpShares.get("vault") || 0;
    const sharesToWithdraw = vaultShares * (sharePercent / 100);
    
    const { amountA, amountB } = this.amm.removeLiquidity(sharesToWithdraw);
    
    console.log(chalk.green(`   ✅ Withdrawn: ${amountA.toFixed(4)} WBTC, ${amountB.toFixed(2)} USDT`));
    
    // Update vault state
    this.bridgedBTC += amountA;
    this.vaultUSDT += amountB;
    this.lpShares.set("vault", vaultShares - sharesToWithdraw);
    
    // Calculate impermanent loss
    const il = this.amm.calculateImpermanentLoss(50000); // Assume initial price was 50k
    console.log(chalk.yellow(`   Impermanent Loss: ${il.toFixed(2)}%`));
    
    return { wbtc: amountA, usdt: amountB };
  }
  
  // Bridge back to Bitcoin
  async bridgeToBitcoin(amountWBTC: number) {
    console.log(chalk.yellow(`\n🌉 Bridging ${amountWBTC} WBTC back to Bitcoin`));
    
    if (amountWBTC > this.bridgedBTC) {
      throw new Error("Insufficient bridged WBTC");
    }
    
    // Simulate bridge delay
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    this.bridgedBTC -= amountWBTC;
    this.vaultBTC += amountWBTC;
    
    console.log(chalk.green(`   ✅ Bridged back successfully`));
    console.log(chalk.gray(`   Vault BTC: ${this.vaultBTC}, Bridged WBTC: ${this.bridgedBTC}`));
    
    return this.vaultBTC;
  }
  
  // Generate proof using garbled circuits (simplified)
  private async generateDepositProof(user: string, btc: number, usdt: number): Promise<string> {
    // In real implementation, this would use garbled circuits
    // to privately verify deposit conditions
    const hash = require('crypto').createHash('sha256');
    hash.update(`${user}:${btc}:${usdt}`);
    return hash.digest('hex');
  }
  
  // Get vault state
  getVaultState() {
    return {
      vaultBTC: this.vaultBTC,
      vaultUSDT: this.vaultUSDT,
      bridgedBTC: this.bridgedBTC,
      lpShares: Array.from(this.lpShares.entries()),
      poolState: this.amm.getPoolState()
    };
  }
}

// Main demo
async function runAMMDemo() {
  console.log(chalk.cyan('\n' + '='.repeat(60)));
  console.log(chalk.cyan.bold('   BitVM3 AMM Liquidity Provision Demo'));
  console.log(chalk.cyan('='.repeat(60)));
  
  console.log(chalk.white('\nThis demo shows how BitVM3 vault provides liquidity to an AMM:'));
  console.log(chalk.gray('1. Users deposit BTC/USDT to trustless vault'));
  console.log(chalk.gray('2. Vault bridges BTC to EVM chain as WBTC'));
  console.log(chalk.gray('3. Deploys WBTC/USDT liquidity to AMM'));
  console.log(chalk.gray('4. Earns trading fees from swaps'));
  console.log(chalk.gray('5. Withdraws and bridges back to Bitcoin'));
  
  const vault = new BitVM3AMMVault();
  
  try {
    // Step 1: Deposits to vault
    console.log(chalk.yellow('\n' + '─'.repeat(60)));
    console.log(chalk.yellow('Step 1: Vault Deposits'));
    console.log(chalk.yellow('─'.repeat(60)));
    
    await vault.depositToVault("Alice", 2.0, 0);
    await vault.depositToVault("Bob", 0, 100000);
    
    // Step 2: Bridge to EVM
    console.log(chalk.yellow('\n' + '─'.repeat(60)));
    console.log(chalk.yellow('Step 2: Bridge to EVM Chain'));
    console.log(chalk.yellow('─'.repeat(60)));
    
    await vault.bridgeToEVM(1.5);
    
    // Step 3: Deploy to AMM
    console.log(chalk.yellow('\n' + '─'.repeat(60)));
    console.log(chalk.yellow('Step 3: Deploy Liquidity to AMM'));
    console.log(chalk.yellow('─'.repeat(60)));
    
    await vault.deployToAMM(1.0, 50000); // 1 WBTC, 50k USDT at 50k price
    
    // Step 4: Simulate trading
    console.log(chalk.yellow('\n' + '─'.repeat(60)));
    console.log(chalk.yellow('Step 4: Trading Activity'));
    console.log(chalk.yellow('─'.repeat(60)));
    
    await vault.simulateTrading(10);
    
    // Step 5: Add more liquidity
    console.log(chalk.yellow('\n' + '─'.repeat(60)));
    console.log(chalk.yellow('Step 5: Add More Liquidity'));
    console.log(chalk.yellow('─'.repeat(60)));
    
    await vault.deployToAMM(0.5, 30000);
    
    // Step 6: Withdraw liquidity
    console.log(chalk.yellow('\n' + '─'.repeat(60)));
    console.log(chalk.yellow('Step 6: Withdraw Liquidity'));
    console.log(chalk.yellow('─'.repeat(60)));
    
    await vault.withdrawFromAMM(50); // Withdraw 50% of LP position
    
    // Step 7: Bridge back
    console.log(chalk.yellow('\n' + '─'.repeat(60)));
    console.log(chalk.yellow('Step 7: Bridge Back to Bitcoin'));
    console.log(chalk.yellow('─'.repeat(60)));
    
    await vault.bridgeToBitcoin(0.5);
    
    // Final state
    console.log(chalk.green('\n' + '='.repeat(60)));
    console.log(chalk.green('Final Vault State'));
    console.log(chalk.green('='.repeat(60)));
    
    const finalState = vault.getVaultState();
    console.log(chalk.white('\nVault Holdings:'));
    console.log(chalk.gray(`  BTC: ${finalState.vaultBTC.toFixed(4)}`));
    console.log(chalk.gray(`  USDT: ${finalState.vaultUSDT.toFixed(2)}`));
    console.log(chalk.gray(`  Bridged WBTC: ${finalState.bridgedBTC.toFixed(4)}`));
    
    console.log(chalk.white('\nAMM Pool State:'));
    console.log(chalk.gray(`  WBTC Reserve: ${finalState.poolState.reserveA.toFixed(4)}`));
    console.log(chalk.gray(`  USDT Reserve: ${finalState.poolState.reserveB.toFixed(2)}`));
    console.log(chalk.gray(`  LP Tokens: ${finalState.poolState.totalShares.toFixed(4)}`));
    console.log(chalk.gray(`  Price: 1 WBTC = ${finalState.poolState.price.priceAInB.toFixed(2)} USDT`));
    
    console.log(chalk.cyan('\n✨ Demo Complete!'));
    console.log(chalk.white('\nKey Achievements:'));
    console.log(chalk.gray('  ✓ Bridged BTC to EVM chain'));
    console.log(chalk.gray('  ✓ Provided liquidity to AMM'));
    console.log(chalk.gray('  ✓ Earned trading fees'));
    console.log(chalk.gray('  ✓ Managed impermanent loss'));
    console.log(chalk.gray('  ✓ Bridged assets back to Bitcoin'));
    
  } catch (error) {
    console.error(chalk.red('\n❌ Error:'), error);
  }
}

// Run demo if called directly
if (require.main === module) {
  runAMMDemo().catch(console.error);
}

export { SimpleAMM, BitVM3AMMVault };