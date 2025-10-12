#!/usr/bin/env ts-node

/**
 * BitVM3 Leveraged Yield Farming Demo
 * 
 * Demonstrates how users leverage BTC to farm yield:
 * - Users deposit BTC as collateral
 * - Borrow USDT against BTC (up to 50% LTV)
 * - Borrowed USDT automatically deployed to yield pools
 * - Earn 8-12% APY on borrowed funds
 * - Liquidation if BTC price drops too much
 * - BitVM verifies all operations trustlessly
 */

import { BitVM3Protocol } from './core/BitVM3Protocol';
import { TransactionManager } from './core/TransactionManager';
import crypto from 'crypto';
import axios from 'axios';

// Minimal GarbledCircuitClient for demo
class GarbledCircuitClient {
    async evaluateWithdrawal(
        withdrawalAmount: number,
        vaultBalance: number,
        additionalConditions: boolean[] = []
    ): Promise<any> {
        // Mock evaluation for demo
        return {
            approved: vaultBalance >= withdrawalAmount,
            proof: crypto.randomBytes(32).toString('hex')
        };
    }
}

// Color codes for terminal output
const colors = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
    dim: '\x1b[2m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    red: '\x1b[31m',
    cyan: '\x1b[36m',
    magenta: '\x1b[35m'
};

class YieldPosition {
    public yieldEarned: number = 0;
    public lastHarvestTime: number;
    
    constructor(
        public protocol: string, // "Aave", "Compound", "Curve"
        public depositedUSDT: number,
        public apy: number // Annual percentage yield
    ) {
        this.lastHarvestTime = Date.now();
    }

    calculateYield(): number {
        const timeElapsed = (Date.now() - this.lastHarvestTime) / (365 * 24 * 60 * 60 * 1000);
        return this.depositedUSDT * this.apy * timeElapsed;
    }

    harvest(): number {
        const earned = this.calculateYield();
        this.yieldEarned += earned;
        this.lastHarvestTime = Date.now();
        return earned;
    }
}

class LeveragedPosition {
    public yieldPositions: YieldPosition[] = [];
    public totalYieldEarned: number = 0;
    
    constructor(
        public borrower: string,
        public collateralBTC: number,
        public borrowedUSDT: number,
        public borrowRate: number, // Borrow APR (e.g., 0.05 = 5%)
        public startTime: number
    ) {}

    getHealthRatio(btcPrice: number): number {
        const collateralValue = this.collateralBTC * btcPrice;
        const debtWithInterest = this.getDebtWithInterest();
        return collateralValue / debtWithInterest;
    }

    getDebtWithInterest(): number {
        const timeElapsed = (Date.now() - this.startTime) / (365 * 24 * 60 * 60 * 1000);
        return this.borrowedUSDT * (1 + this.borrowRate * timeElapsed);
    }

    getNetAPY(): number {
        // Calculate weighted average yield APY minus borrow rate
        let totalAPY = 0;
        let totalDeposited = 0;
        
        for (const pos of this.yieldPositions) {
            totalAPY += pos.apy * pos.depositedUSDT;
            totalDeposited += pos.depositedUSDT;
        }
        
        const avgYieldAPY = totalDeposited > 0 ? totalAPY / totalDeposited : 0;
        return avgYieldAPY - this.borrowRate;
    }

    getLiquidationPrice(): number {
        // Liquidation at 150% collateralization
        return (this.getDebtWithInterest() * 1.5) / this.collateralBTC;
    }

    harvestYields(): number {
        let totalHarvested = 0;
        for (const pos of this.yieldPositions) {
            totalHarvested += pos.harvest();
        }
        this.totalYieldEarned += totalHarvested;
        return totalHarvested;
    }
}

class LeveragedYieldProtocol {
    private positions: Map<string, LeveragedPosition> = new Map();
    private lenderPool: number = 0; // USDT available for lending
    private btcPrice: number = 50000; // Current BTC price in USDT
    private liquidationThreshold: number = 1.5; // 150% collateralization ratio
    private protocol: BitVM3Protocol;
    private txManager: TransactionManager;
    
    // Available yield protocols
    private yieldProtocols = [
        { name: 'Aave', apy: 0.08, risk: 'Low' },
        { name: 'Compound', apy: 0.09, risk: 'Low' },
        { name: 'Curve', apy: 0.12, risk: 'Medium' },
        { name: 'Yearn', apy: 0.15, risk: 'High' }
    ];

    constructor() {
        this.protocol = new BitVM3Protocol();
        this.txManager = new TransactionManager();
    }

    async depositToLendingPool(lender: string, usdtAmount: number): Promise<void> {
        console.log(`\n${colors.green}💰 ${lender} depositing ${usdtAmount.toLocaleString()} USDT to lending pool${colors.reset}`);
        this.lenderPool += usdtAmount;
        console.log(`   Pool size: ${this.lenderPool.toLocaleString()} USDT`);
        console.log(`   Base lending APY: ${this.calculateLendingAPY()}%`);
    }

    async createLeveragedPosition(
        borrower: string, 
        collateralBTC: number, 
        borrowUSDT: number,
        yieldStrategy: string[]
    ): Promise<string> {
        console.log(`\n${colors.blue}📋 Creating leveraged yield position for ${borrower}${colors.reset}`);
        
        // BitVM Setup Phase - ALL parties must be defined upfront
        console.log(`\n${colors.yellow}   ⚡ BitVM Vault Setup - ALL Parties Fixed at Creation:${colors.reset}`);
        console.log(`   ${colors.red}⚠️  Critical Limitation: Cannot modify participants after setup!${colors.reset}`);
        console.log(`\n   ${colors.cyan}Vault Operators (2-of-3 multisig):${colors.reset}`);
        console.log(`     • Alice (Vault Creator/Operator)`);
        console.log(`     • BitVM Protocol DAO`);  
        console.log(`     • Trusted Oracle Service`);
        console.log(`\n   ${colors.cyan}Pre-designated Liquidators:${colors.reset}`);
        console.log(`     • Eve (Professional Liquidator)`);
        console.log(`     • Frank (Market Maker)`);
        console.log(`     • Protocol Treasury`);
        console.log(`\n   ${colors.cyan}Fixed Participants:${colors.reset}`);
        console.log(`     • ${borrower} (Borrower) - this position only`);
        console.log(`     • Lender Pool (managed by operators)`);
        console.log(`\n   ${colors.red}What CANNOT be changed later:${colors.reset}`);
        console.log(`     ✗ Cannot add new operators`);
        console.log(`     ✗ Cannot add new liquidators`);
        console.log(`     ✗ Cannot add new borrowers to THIS vault`);
        console.log(`     ✗ Cannot change multisig threshold`);
        console.log(`\n   ${colors.green}What CAN happen:${colors.reset}`);
        console.log(`     ✓ Create NEW vaults with different participants`);
        console.log(`     ✓ Operators can manage funds within pre-signed rules`);
        console.log(`     ✓ Liquidators can act when conditions are met`);
        
        // Check collateralization ratio (max 50% LTV = 200% collateralization)
        const collateralValue = collateralBTC * this.btcPrice;
        const initialRatio = collateralValue / borrowUSDT;
        
        if (initialRatio < 2.0) {
            throw new Error(`Insufficient collateral. Max 50% LTV (need ${(borrowUSDT * 2 / this.btcPrice).toFixed(3)} BTC)`);
        }

        if (borrowUSDT > this.lenderPool) {
            throw new Error(`Insufficient liquidity. Pool has ${this.lenderPool} USDT`);
        }

        // Create position with 5% borrow rate
        const position = new LeveragedPosition(
            borrower,
            collateralBTC,
            borrowUSDT,
            0.05, // 5% borrow APR
            Date.now()
        );

        // Deploy borrowed USDT to yield protocols
        console.log(`\n${colors.cyan}🌾 Deploying ${borrowUSDT.toLocaleString()} USDT to yield protocols:${colors.reset}`);
        
        const amountPerProtocol = borrowUSDT / yieldStrategy.length;
        for (const protocolName of yieldStrategy) {
            const protocol = this.yieldProtocols.find(p => p.name === protocolName);
            if (protocol) {
                const yieldPos = new YieldPosition(protocol.name, amountPerProtocol, protocol.apy);
                position.yieldPositions.push(yieldPos);
                console.log(`   → ${protocol.name}: ${amountPerProtocol.toLocaleString()} USDT @ ${(protocol.apy * 100).toFixed(1)}% APY (${protocol.risk} risk)`);
            }
        }

        const positionId = crypto.randomBytes(16).toString('hex');
        this.positions.set(positionId, position);
        this.lenderPool -= borrowUSDT;

        // Generate BitVM proof
        const proof = await this.generateLoanProof(position);

        const netAPY = position.getNetAPY();
        console.log(`\n   ✅ Position created: ${positionId.slice(0, 8)}...`);
        console.log(`   Collateral: ${collateralBTC} BTC ($${collateralValue.toLocaleString()})`);
        console.log(`   Borrowed: ${borrowUSDT.toLocaleString()} USDT @ 5% APR`);
        console.log(`   Health Ratio: ${colors.green}${initialRatio.toFixed(2)}${colors.reset}`);
        console.log(`   Liquidation Price: $${position.getLiquidationPrice().toLocaleString()}`);
        console.log(`   Net APY: ${netAPY >= 0 ? colors.green : colors.red}${(netAPY * 100).toFixed(2)}%${colors.reset} (yield - borrow rate)`);
        console.log(`   BitVM Proof: ${proof.slice(0, 16)}...`);

        return positionId;
    }

    async checkPosition(positionId: string): Promise<boolean> {
        const position = this.positions.get(positionId);
        if (!position) throw new Error('Position not found');

        const healthRatio = position.getHealthRatio(this.btcPrice);
        const isLiquidatable = healthRatio < this.liquidationThreshold;
        const yieldsEarned = position.harvestYields();

        console.log(`\n${colors.yellow}📊 Position Status ${positionId.slice(0, 8)}...${colors.reset}`);
        console.log(`   Current BTC Price: $${this.btcPrice.toLocaleString()}`);
        console.log(`   Collateral Value: $${(position.collateralBTC * this.btcPrice).toLocaleString()}`);
        console.log(`   Debt + Interest: $${position.getDebtWithInterest().toFixed(2)}`);
        console.log(`   Health Ratio: ${healthRatio < this.liquidationThreshold ? colors.red : colors.green}${healthRatio.toFixed(2)}${colors.reset}`);
        
        // Show yield farming performance
        console.log(`\n   ${colors.cyan}🌾 Yield Farming Performance:${colors.reset}`);
        for (const yieldPos of position.yieldPositions) {
            console.log(`   • ${yieldPos.protocol}: +$${yieldPos.yieldEarned.toFixed(2)} earned`);
        }
        console.log(`   Total Yield Earned: ${colors.green}+$${position.totalYieldEarned.toFixed(2)}${colors.reset}`);
        console.log(`   Net APY: ${position.getNetAPY() >= 0 ? colors.green : colors.red}${(position.getNetAPY() * 100).toFixed(2)}%${colors.reset}`);
        
        console.log(`   Status: ${isLiquidatable ? colors.red + 'LIQUIDATABLE' : colors.green + 'HEALTHY'}${colors.reset}`);

        return isLiquidatable;
    }

    async liquidate(positionId: string, liquidator: string): Promise<void> {
        const position = this.positions.get(positionId);
        if (!position) throw new Error('Position not found');

        const healthRatio = position.getHealthRatio(this.btcPrice);
        if (healthRatio >= this.liquidationThreshold) {
            throw new Error(`Position is healthy (ratio: ${healthRatio.toFixed(2)}). Cannot liquidate.`);
        }

        console.log(`\n${colors.red}⚡ LIQUIDATION TRIGGERED${colors.reset}`);
        console.log(`   Liquidator: ${liquidator}`);
        console.log(`   Position: ${positionId.slice(0, 8)}...`);

        // Calculate liquidation details
        const debt = position.getDebtWithInterest();
        const liquidationBonus = debt * 0.05;
        const yieldsEarned = position.totalYieldEarned;
        const btcToLiquidate = (debt * 1.05) / this.btcPrice; // BTC needed to cover debt + bonus

        // BitVM limitation: liquidators must be predetermined
        console.log(`\n   ${colors.yellow}⚠️  BitVM Liquidation Limitation:${colors.reset}`);
        console.log(`   ${colors.red}Liquidators must be pre-designated during vault setup!${colors.reset}`);
        console.log(`   • ${liquidator} was included in initial Taproot ceremony`);
        console.log(`   • Pre-signed transaction allows ${liquidator} to liquidate`);
        console.log(`   • Cannot add new liquidators after vault creation`);
        
        console.log(`\n   ${colors.cyan}📝 Pre-signed Liquidation Path:${colors.reset}`);
        console.log(`   1. ${liquidator} provides ${debt.toFixed(2)} USDT to vault`);
        console.log(`   2. Executes pre-signed Taproot branch (signed at setup)`);
        console.log(`   3. BitVM verifies: health < 1.5 AND payment received`);
        console.log(`   4. ${liquidator} receives ${btcToLiquidate.toFixed(4)} BTC`);

        // Use garbled circuits to verify liquidation privately
        const gcClient = new GarbledCircuitClient();
        const liquidationProof = await this.verifyLiquidationWithGarbledCircuit(
            position,
            this.btcPrice,
            liquidator
        );

        console.log(`\n   ${colors.cyan}💰 Liquidation Economics:${colors.reset}`);
        console.log(`   Debt to Repay: ${debt.toFixed(2)} USDT`);
        console.log(`   BTC Collateral Value: $${(position.collateralBTC * this.btcPrice).toFixed(2)}`);
        console.log(`   BTC Released to Liquidator: ${btcToLiquidate.toFixed(4)} BTC`);
        console.log(`   Liquidator Profit: ${liquidationBonus.toFixed(2)} USDT (5%)`);
        console.log(`   Remaining BTC to Borrower: ${(position.collateralBTC - btcToLiquidate).toFixed(4)} BTC`);
        
        console.log(`\n   ${colors.green}✅ Verification Proofs:${colors.reset}`);
        console.log(`   Garbled Circuit: ${liquidationProof.slice(0, 16)}...`);
        
        // Generate BitVM proof for on-chain verification
        const bitvmProof = await this.generateLiquidationProof(position, liquidator);
        console.log(`   BitVM Script: ${bitvmProof.slice(0, 16)}... (530KB on-chain)`);

        // Remove position
        this.positions.delete(positionId);
        this.lenderPool += debt; // Return debt to pool

        console.log(`\n   ${colors.green}✅ Liquidation complete via BitVM Taproot path${colors.reset}`);
    }

    async addCollateral(positionId: string, additionalBTC: number): Promise<void> {
        const position = this.positions.get(positionId);
        if (!position) throw new Error('Position not found');

        console.log(`\n${colors.blue}🔒 Attempting to add collateral to position ${positionId.slice(0, 8)}...${colors.reset}`);
        console.log(`   Current Collateral: ${position.collateralBTC} BTC`);
        console.log(`   Additional Collateral: ${additionalBTC} BTC`);
        
        console.log(`\n${colors.red}   ❌ BitVM Limitation: Cannot modify existing vault!${colors.reset}`);
        console.log(`   Pre-signed transactions are immutable:`);
        console.log(`   • Collateral amount was fixed at creation`);
        console.log(`   • Liquidation thresholds assume original collateral`);
        console.log(`   • Cannot update pre-signed Taproot paths`);
        
        console.log(`\n${colors.yellow}   📝 Options for Additional Collateral:${colors.reset}`);
        console.log(`\n   ${colors.cyan}Option 1: Create Supplementary Vault${colors.reset}`);
        console.log(`   • Create new vault for additional ${additionalBTC} BTC`);
        console.log(`   • Link to existing position via protocol layer`);
        console.log(`   • Separate pre-signed transactions for new collateral`);
        console.log(`   • Complex to manage multiple vaults per user`);
        
        console.log(`\n   ${colors.cyan}Option 2: Over-Collateralize Initially${colors.reset}`);
        console.log(`   • Deposit max expected collateral upfront`);
        console.log(`   • Pre-sign multiple spending paths:`);
        console.log(`     - Path 1: If using 2 BTC collateral`);
        console.log(`     - Path 2: If using 3 BTC collateral`);
        console.log(`     - Path 3: If using 4 BTC collateral`);
        console.log(`   • Downsides: Capital inefficient, limited flexibility`);
        
        console.log(`\n   ${colors.cyan}Option 3: Close and Reopen${colors.reset}`);
        console.log(`   • Close current position (repay loan)`);
        console.log(`   • Create new vault with ${position.collateralBTC + additionalBTC} BTC`);
        console.log(`   • Downside: Gas costs, potential loss of yield position`);
        
        console.log(`\n   ${colors.green}✅ Recommended Approach: Vault Composition${colors.reset}`);
        console.log(`   Creating supplementary vault for additional collateral...`);
        
        // Simulate creating a new vault
        const supplementaryVaultId = crypto.randomBytes(16).toString('hex');
        console.log(`   New Vault ID: ${supplementaryVaultId.slice(0, 8)}...`);
        console.log(`   Linked to Primary: ${positionId.slice(0, 8)}...`);
        console.log(`   Additional collateral secured in new vault`);
        console.log(`   Combined Health Ratio: ${((position.collateralBTC + additionalBTC) * this.btcPrice / position.getDebtWithInterest()).toFixed(2)}`);
    }

    async repayLoan(positionId: string, amount: number): Promise<void> {
        const position = this.positions.get(positionId);
        if (!position) throw new Error('Position not found');

        const totalDebt = position.getDebtWithInterest();
        const yieldsEarned = position.totalYieldEarned;
        const netProfit = yieldsEarned - (totalDebt - position.borrowedUSDT);
        
        console.log(`\n${colors.cyan}💸 Closing position ${positionId.slice(0, 8)}...${colors.reset}`);
        console.log(`   Original Loan: ${position.borrowedUSDT.toLocaleString()} USDT`);
        console.log(`   Total Debt: ${totalDebt.toFixed(2)} USDT`);
        console.log(`   Yields Earned: ${colors.green}+${yieldsEarned.toFixed(2)} USDT${colors.reset}`);
        console.log(`   Net Profit: ${netProfit >= 0 ? colors.green : colors.red}${netProfit >= 0 ? '+' : ''}${netProfit.toFixed(2)} USDT${colors.reset}`);
        console.log(`   Payment: ${amount.toFixed(2)} USDT`);

        if (amount >= totalDebt) {
            // Full repayment
            console.log(`   ${colors.green}✅ Position closed successfully${colors.reset}`);
            console.log(`   Collateral Released: ${position.collateralBTC} BTC`);
            console.log(`   Final P&L: ${netProfit >= 0 ? colors.green : colors.red}${netProfit >= 0 ? '+' : ''}${netProfit.toFixed(2)} USDT${colors.reset}`);
            this.positions.delete(positionId);
            this.lenderPool += totalDebt;
        } else {
            // Partial repayment
            position.borrowedUSDT -= amount;
            console.log(`   Remaining Debt: ${(totalDebt - amount).toFixed(2)} USDT`);
            console.log(`   New Health Ratio: ${position.getHealthRatio(this.btcPrice).toFixed(2)}`);
            this.lenderPool += amount;
        }
    }

    updateBTCPrice(newPrice: number): void {
        const oldPrice = this.btcPrice;
        this.btcPrice = newPrice;
        const change = ((newPrice - oldPrice) / oldPrice) * 100;
        
        console.log(`\n${colors.magenta}📊 BTC Price Update${colors.reset}`);
        console.log(`   Old Price: $${oldPrice.toLocaleString()}`);
        console.log(`   New Price: $${newPrice.toLocaleString()}`);
        console.log(`   Change: ${change >= 0 ? colors.green : colors.red}${change >= 0 ? '+' : ''}${change.toFixed(2)}%${colors.reset}`);

        // Check all positions for liquidation risk
        let atRisk = 0;
        for (const [id, position] of this.positions) {
            const ratio = position.getHealthRatio(newPrice);
            if (ratio < 2.0) {
                atRisk++;
                if (ratio < this.liquidationThreshold) {
                    console.log(`   ${colors.red}⚠️  Position ${id.slice(0, 8)} is LIQUIDATABLE!${colors.reset}`);
                } else {
                    console.log(`   ${colors.yellow}⚠️  Position ${id.slice(0, 8)} at risk (ratio: ${ratio.toFixed(2)})${colors.reset}`);
                }
            }
        }
        
        if (atRisk === 0 && this.positions.size > 0) {
            console.log(`   ${colors.green}✓ All positions healthy${colors.reset}`);
        }
    }

    private calculateLendingAPY(): string {
        // Dynamic APY based on utilization
        const utilization = (this.lenderPool > 0) ? 
            (1 - this.lenderPool / (this.lenderPool + this.getTotalBorrowed())) : 0;
        const apy = 5 + utilization * 10; // 5-15% APY
        return apy.toFixed(1);
    }

    private getTotalBorrowed(): number {
        let total = 0;
        for (const position of this.positions.values()) {
            total += position.borrowedUSDT;
        }
        return total;
    }

    private async generateLoanProof(position: LeveragedPosition): Promise<string> {
        // Simulate BitVM proof generation for loan creation
        const witness = {
            collateral: position.collateralBTC,
            borrowed: position.borrowedUSDT,
            btcPrice: this.btcPrice,
            yieldPositions: position.yieldPositions.length,
            timestamp: position.startTime
        };
        
        // In real implementation, this would generate a Groth16 proof
        return crypto.createHash('sha256')
            .update(JSON.stringify(witness))
            .digest('hex');
    }

    private async generateLiquidationProof(
        position: LeveragedPosition,
        liquidator: string
    ): Promise<string> {
        // Generate BitVM proof for liquidation
        const witness = {
            position: position,
            liquidator: liquidator,
            btcPrice: this.btcPrice,
            healthRatio: position.getHealthRatio(this.btcPrice),
            yieldsEarned: position.totalYieldEarned,
            timestamp: Date.now()
        };
        
        return crypto.createHash('sha256')
            .update(JSON.stringify(witness))
            .digest('hex');
    }

    private async verifyLiquidationWithGarbledCircuit(
        position: LeveragedPosition,
        btcPrice: number,
        liquidator: string
    ): Promise<string> {
        // Use garbled circuits for private verification
        // This ensures liquidator doesn't learn exact position details
        const gcClient = new GarbledCircuitClient();
        
        try {
            // Private inputs: position details
            // Public output: valid/invalid liquidation
            const result = await gcClient.evaluateWithdrawal(
                position.getDebtWithInterest(),
                position.collateralBTC * btcPrice,
                [true, true] // Additional conditions
            );
            
            return result.proof || crypto.randomBytes(32).toString('hex');
        } catch (error) {
            // Fallback to mock proof
            return crypto.randomBytes(32).toString('hex');
        }
    }

    displayPoolStats(): void {
        const totalBorrowed = this.getTotalBorrowed();
        const utilization = totalBorrowed / (this.lenderPool + totalBorrowed) * 100;
        
        let totalYieldsEarned = 0;
        for (const position of this.positions.values()) {
            totalYieldsEarned += position.totalYieldEarned;
        }
        
        console.log(`\n${colors.bright}═══════════════════════════════════════════════════════${colors.reset}`);
        console.log(`${colors.bright}             LEVERAGED YIELD POOL STATISTICS${colors.reset}`);
        console.log(`${colors.bright}═══════════════════════════════════════════════════════${colors.reset}`);
        console.log(`  Available Liquidity: ${this.lenderPool.toLocaleString()} USDT`);
        console.log(`  Total Borrowed: ${totalBorrowed.toLocaleString()} USDT`);
        console.log(`  Utilization Rate: ${utilization.toFixed(1)}%`);
        console.log(`  Active Positions: ${this.positions.size}`);
        console.log(`  Total Yields Earned: ${colors.green}+$${totalYieldsEarned.toFixed(2)}${colors.reset}`);
        console.log(`  Lending APY: ${this.calculateLendingAPY()}%`);
        console.log(`  BTC Price: $${this.btcPrice.toLocaleString()}`);
        console.log(`${colors.bright}═══════════════════════════════════════════════════════${colors.reset}`);
    }
}

async function runLendingDemo() {
    console.log('\n');
    console.log('═'.repeat(60));
    console.log('   BitVM3 Leveraged Yield Farming Demo');
    console.log('═'.repeat(60));
    
    console.log('\nThis demo shows how to leverage BTC for yield farming:');
    console.log('• Use BTC as collateral to borrow USDT (up to 50% LTV)');
    console.log('• Borrowed USDT automatically deployed to yield protocols');
    console.log('• Earn 8-15% APY while paying 5% borrow rate');
    console.log('• Automatic liquidation if BTC price drops');
    console.log('• All verified trustlessly via BitVM on Bitcoin');

    const protocol = new LeveragedYieldProtocol();

    // Step 1: Lenders provide liquidity
    console.log(`\n${colors.bright}${'─'.repeat(60)}${colors.reset}`);
    console.log(`${colors.bright}Step 1: Lenders Provide Liquidity${colors.reset}`);
    console.log(`${colors.bright}${'─'.repeat(60)}${colors.reset}`);
    
    await protocol.depositToLendingPool('Alice', 200000);
    await protocol.depositToLendingPool('Bob', 150000);
    
    // Step 2: Create leveraged yield positions
    console.log(`\n${colors.bright}${'─'.repeat(60)}${colors.reset}`);
    console.log(`${colors.bright}Step 2: Create Leveraged Yield Positions${colors.reset}`);
    console.log(`${colors.bright}${'─'.repeat(60)}${colors.reset}`);
    
    // Charlie uses 2 BTC to borrow 50k USDT for conservative yield farming
    const position1 = await protocol.createLeveragedPosition(
        'Charlie', 
        2.0, 
        50000,
        ['Aave', 'Compound']  // Conservative 8-9% APY
    );
    
    // David uses 1.5 BTC to borrow 30k USDT for aggressive yield farming
    const position2 = await protocol.createLeveragedPosition(
        'David', 
        1.5, 
        30000,
        ['Curve', 'Yearn']  // Aggressive 12-15% APY
    );
    
    // Step 3: Monitor positions and yield performance
    console.log(`\n${colors.bright}${'─'.repeat(60)}${colors.reset}`);
    console.log(`${colors.bright}Step 3: Monitor Positions & Yield Performance${colors.reset}`);
    console.log(`${colors.bright}${'─'.repeat(60)}${colors.reset}`);
    
    // Simulate some time passing for yield generation
    await new Promise(resolve => setTimeout(resolve, 100));
    
    await protocol.checkPosition(position1);
    await protocol.checkPosition(position2);
    
    // Step 4: Attempt to add collateral
    console.log(`\n${colors.bright}${'─'.repeat(60)}${colors.reset}`);
    console.log(`${colors.bright}Step 4: Attempting to Add Collateral${colors.reset}`);
    console.log(`${colors.bright}${'─'.repeat(60)}${colors.reset}`);
    
    // Charlie wants to add more collateral to improve health ratio
    await protocol.addCollateral(position1, 1.0);
    
    // Step 5: Market crash simulation
    console.log(`\n${colors.bright}${'─'.repeat(60)}${colors.reset}`);
    console.log(`${colors.bright}Step 5: Market Price Movement${colors.reset}`);
    console.log(`${colors.bright}${'─'.repeat(60)}${colors.reset}`);
    
    protocol.updateBTCPrice(45000); // 10% drop
    console.log(`\n${colors.magenta}⚠️  Checking position health after price drop...${colors.reset}`);
    await protocol.checkPosition(position1);
    
    protocol.updateBTCPrice(35000); // 30% total drop - triggers liquidations
    
    // Step 6: Liquidation
    console.log(`\n${colors.bright}${'─'.repeat(60)}${colors.reset}`);
    console.log(`${colors.bright}Step 6: Liquidation Process${colors.reset}`);
    console.log(`${colors.bright}${'─'.repeat(60)}${colors.reset}`);
    
    const canLiquidate1 = await protocol.checkPosition(position1);
    if (canLiquidate1) {
        await protocol.liquidate(position1, 'Eve (Liquidator)');
    }
    
    // Step 7: Position closure
    console.log(`\n${colors.bright}${'─'.repeat(60)}${colors.reset}`);
    console.log(`${colors.bright}Step 7: Close Profitable Position${colors.reset}`);
    console.log(`${colors.bright}${'─'.repeat(60)}${colors.reset}`);
    
    await protocol.repayLoan(position2, 30100); // David closes position with profit
    
    // Final stats
    protocol.displayPoolStats();
    
    console.log(`\n${colors.green}✨ Demo Complete!${colors.reset}`);
    console.log('\nKey Takeaways:');
    console.log('• Use BTC as collateral to access yield opportunities');
    console.log('• Earn 8-15% APY on borrowed funds (minus 5% borrow cost)');
    console.log('• Automatic deployment to yield protocols for passive income');
    console.log('• BitVM verifies all operations trustlessly on Bitcoin');
    console.log('• Liquidations protect lenders while allowing leverage');
}

// Run the demo
runLendingDemo().catch(console.error);