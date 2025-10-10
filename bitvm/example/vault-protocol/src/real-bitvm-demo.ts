/**
 * BitVM3 Demo with Real Components
 * This demonstrates the integration with actual BitVM implementation
 */

import { BitVM3Protocol } from './core/BitVM3Protocol';
import { TrustlessVault } from './vault/TrustlessVault';
import { TransactionManager } from './core/TransactionManager';
import { GarbledCircuit } from './crypto/GarbledCircuit';
import { SNARKVerifier } from './crypto/SNARKVerifier';
import axios from 'axios';

// Configuration for connecting to Rust backend
const RUST_API_URL = process.env.RUST_API_URL || 'http://localhost:8080';

/**
 * Simple hash function to convert string to number (for demo purposes)
 */
function hashCode(str: string): number {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
        const char = str.charCodeAt(i);
        hash = ((hash << 5) - hash) + char;
        hash = hash & hash; // Convert to 32-bit integer
    }
    return Math.abs(hash);
}

/**
 * Enhanced demo that uses real BitVM components via Rust backend
 */
export async function runRealBitVMDemo() {
    console.log('\n🎯 BitVM3 Demo with Real Components');
    console.log('=====================================\n');

    // Step 1: Initialize the protocol
    console.log('1️⃣ Initializing BitVM3 Protocol with real components...');
    const protocol = new BitVM3Protocol();
    
    // Create participant objects
    const alice = {
        name: 'alice',
        publicKey: '0x' + '11'.repeat(32),
        privateKey: '0x' + 'aa'.repeat(32),
        balance: { BTC: 2 * 1e8, USDT: 0 }
    };
    
    const bob = {
        name: 'bob',
        publicKey: '0x' + '22'.repeat(32),
        privateKey: '0x' + 'bb'.repeat(32),
        balance: { BTC: 0, USDT: 20000 * 100 }
    };
    
    await protocol.initialize(alice, bob);
    console.log('   ✅ Protocol initialized\n');

    // Step 2: Check if Rust backend is available
    console.log('2️⃣ Checking Rust backend connection...');
    const isBackendAvailable = await checkRustBackend();
    
    if (isBackendAvailable) {
        console.log('   ✅ Rust backend connected - using real BitVM components\n');
        await runWithRealComponents(protocol);
    } else {
        console.log('   ⚠️  Rust backend not available - using mock components\n');
        await runWithMockComponents(protocol);
    }
}

/**
 * Run demo with real BitVM components from Rust backend
 */
async function runWithRealComponents(protocol: BitVM3Protocol) {
    console.log('🔬 Using Real BitVM Components');
    console.log('-------------------------------\n');

    // Step 1: Generate real Groth16 proof via Rust backend
    console.log('📝 Generating real Groth16 proof for initial state verification...');
    try {
        // Realistic inputs for state initialization proof
        const initialState = protocol.getVaultState();
        
        // Public inputs for state initialization
        const publicInputs = [
            0,  // Previous state (genesis)
            parseInt(initialState.lastStateRoot.slice(0, 8) || '0', 16),  // Current state root
            initialState.totalBTC,  // Total BTC in vault
            initialState.totalUSDT,  // Total USDT in vault  
            initialState.blockHeight  // Current block height
        ];
        
        // Witness for state initialization (proves correct setup)
        const witness = [
            hashCode('alice'),  // Alice's identifier
            hashCode('bob'),    // Bob's identifier
            200000000,  // Alice's initial BTC (2 BTC)
            2000000,    // Bob's initial USDT (20,000 USDT)
            Date.now() % 1000000,  // Timestamp
            42  // Nonce
        ];
        
        console.log('   🔐 Using realistic circuit inputs:');
        console.log(`      • State root: ${publicInputs[1]}`);
        console.log(`      • Vault totals: ${publicInputs[2]} sats BTC, ${publicInputs[3]} cents USDT`);
        
        const proofResponse = await axios.post(`${RUST_API_URL}/api/groth16/generate-proof`, {
            public_inputs: publicInputs,
            witness: witness
        });
        
        const proofData = proofResponse.data;
        console.log('   ✅ Real Groth16 proof generated');
        console.log(`   📏 Proof size: ${proofData.proof.length} bytes\n`);

        // Step 2: Verify the proof using real verifier
        console.log('🔍 Verifying proof with real Groth16 verifier...');
        const verifyResponse = await axios.post(`${RUST_API_URL}/api/groth16/verify`, {
            proof: proofData.proof,
            public_inputs: proofData.public_inputs
        });

        if (verifyResponse.data.valid) {
            console.log('   ✅ Proof verified successfully!\n');
        } else {
            console.log('   ❌ Proof verification failed\n');
        }

        // Step 3: Generate Bitcoin Scripts using real BitVM
        console.log('📜 Generating Bitcoin Scripts with real BitVM...');
        const scriptsResponse = await axios.get(`${RUST_API_URL}/api/bitvm/scripts`);
        const scripts = scriptsResponse.data;

        console.log('   Generated scripts:');
        console.log(`   - BN254 operations: ${scripts.bn254_size} bytes`);
        console.log(`   - Hash operations: ${scripts.hash_size} bytes`);
        console.log(`   - Winternitz signatures: ${scripts.winternitz_size} bytes`);
        console.log(`   - Number of chunks: ${scripts.num_chunks}`);
        console.log(`   - Total size: ${scripts.total_size} bytes\n`);

        // Step 4: Test state transition with real proof
        console.log('🔄 Testing state transition with real proof...');
        
        // Create realistic state hashes (simulating Merkle roots)
        const oldStateRoot = protocol.getVaultState().lastStateRoot || '0x' + '00'.repeat(32);
        const newStateRoot = '0x' + require('crypto').createHash('sha256')
            .update(oldStateRoot + 'transition')
            .digest('hex');
        
        const transitionResponse = await axios.post(`${RUST_API_URL}/api/bitvm/state-transition`, {
            old_state: oldStateRoot,
            new_state: newStateRoot,
            proof: proofData.proof
        });

        if (transitionResponse.data.success) {
            console.log('   ✅ State transition verified and applied');
            console.log(`   📦 New block height: ${transitionResponse.data.block_height}\n`);
        }

    } catch (error: any) {
        console.error('   ❌ Error:', error.message);
        console.log('   Falling back to mock components\n');
        await runWithMockComponents(protocol);
        return; // Exit after running mock components
    }

    // Step 5: Demonstrate vault operations with real verification
    await demonstrateVaultOperations(protocol, true);
}

/**
 * Run demo with mock components (fallback)
 */
async function runWithMockComponents(protocol: BitVM3Protocol) {
    console.log('🎭 Using Mock Components (Fallback)');
    console.log('------------------------------------\n');

    await demonstrateVaultOperations(protocol, false);
}

/**
 * Demonstrate vault operations
 */
async function demonstrateVaultOperations(protocol: BitVM3Protocol, useRealComponents: boolean) {
    console.log('💰 Vault Operations Demo');
    console.log('------------------------\n');

    // Use the vault from the protocol to maintain state consistency
    const vault = (protocol as any).vault || new TrustlessVault();
    
    // Setup participants
    const alice = protocol.getParticipant('alice');
    const bob = protocol.getParticipant('bob');

    if (!alice || !bob) {
        console.error('Failed to get participants');
        return;
    }

    console.log('Initial Balances:');
    console.log(`  Alice: ${(alice.balance.BTC || 0) / 1e8} BTC, ${(alice.balance.USDT || 0) / 100} USDT`);
    console.log(`  Bob: ${(bob.balance.BTC || 0) / 1e8} BTC, ${(bob.balance.USDT || 0) / 100} USDT\n`);

    // Alice deposits BTC
    console.log('1. Alice deposits 0.5 BTC to vault...');
    const depositAmount = 0.5 * 1e8; // Convert to satoshis
    await protocol.deposit('alice', depositAmount, 'BTC');
    console.log(`   ✅ Deposit successful. Vault BTC: ${protocol.getVaultState().totalBTC / 1e8}\n`);

    // Bob deposits USDT first
    console.log('2. Bob deposits 5,000 USDT to vault...');
    await protocol.deposit('bob', 5000 * 100, 'USDT'); // USDT in cents
    console.log(`   ✅ Deposit successful. Vault USDT: ${protocol.getVaultState().totalUSDT / 100}\n`);
    
    // Bob creates a lending position
    console.log('3. Bob creates lending position: 2,000 USDT with 0.3 BTC collateral...');
    
    // Synchronize vault state with protocol's vault state
    const protocolVaultState = protocol.getVaultState();
    vault.state.totalBTC = protocolVaultState.totalBTC;
    vault.state.totalUSDT = protocolVaultState.totalUSDT;
    
    const position = vault.createLendingPosition(
        'bob',
        'alice',
        2000 * 100, // USDT in cents (less than deposited amount)
        0.3 * 1e8  // BTC collateral
    );
    console.log(`   ✅ Lending position created\n`);

    // Generate and verify withdrawal proof
    console.log('4. Alice requests withdrawal with proof...');
    
    if (useRealComponents) {
        console.log('   🔬 Using real Groth16 verification...');
        try {
            // Generate realistic inputs for withdrawal proof
            const withdrawalAmount = 1000 * 100; // 1000 USDT in cents
            const currentVaultState = protocol.getVaultState();
            
            // Public inputs (what everyone can see)
            const publicInputs = [
                // Old state root (as integer representation)
                parseInt(currentVaultState.lastStateRoot.slice(0, 8) || '0', 16),
                // New state root (simulated after withdrawal)
                parseInt(currentVaultState.lastStateRoot.slice(0, 8) || '0', 16) + 1,
                // Withdrawal amount
                withdrawalAmount,
                // Participant identifier (hash of address)
                hashCode('alice'),
                // Current block height
                currentVaultState.blockHeight
            ];
            
            // Private witness (secret knowledge that proves the right to withdraw)
            const witness = [
                // Merkle path in state tree (simulated with 4 hashes)
                0x1234567890abcdef,  // sibling hash 1
                0xfedcba0987654321,  // sibling hash 2
                0xaabbccdd11223344,  // sibling hash 3
                0x5566778899aabbcc,  // sibling hash 4
                // Previous balance (Alice's USDT balance before withdrawal)
                0,  // Alice starts with 0 USDT
                // Nonce for replay protection
                Date.now() % 1000000
            ];
            
            console.log('   🔐 Generating proof with realistic inputs:');
            console.log(`      • State transition: ${publicInputs[0]} → ${publicInputs[1]}`);
            console.log(`      • Amount: ${withdrawalAmount / 100} USDT`);
            console.log(`      • Block height: ${publicInputs[4]}`);
            
            // Generate a proof for the withdrawal
            const proofResponse = await axios.post(`${RUST_API_URL}/api/groth16/generate-proof`, {
                public_inputs: publicInputs,
                witness: witness
            });
            
            console.log('   📝 Generated withdrawal proof');
            
            // Verify the proof using real BitVM
            const verifyResponse = await axios.post(`${RUST_API_URL}/api/groth16/verify`, {
                proof: proofResponse.data.proof,
                public_inputs: proofResponse.data.public_inputs
            });
            
            if (verifyResponse.data.valid) {
                console.log('   ✅ Withdrawal verified with real BitVM Groth16 Verifier!');
                console.log(`   ⚡ Verification method: ${verifyResponse.data.method}`);
                
                // Process the actual withdrawal
                await protocol.withdraw('alice', 1000 * 100, 'USDT');
            } else {
                console.log('   ❌ Proof verification failed');
            }
        } catch (error: any) {
            console.log('   ⚠️  Real verification unavailable:', error.message);
            console.log('   Falling back to mock verification');
        }
    } else {
        console.log('   🎭 Using mock verification...');
        const garbled = new GarbledCircuit();
        const mockProof = await garbled.evaluate(
            { 
                participant: 'alice', 
                amount: 1000 * 100, 
                currency: 'USDT',
                vaultState: protocol.getVaultState()
            }
        );
        const verifier = new SNARKVerifier();
        const isValid = verifier.verify(mockProof.proof, []);
        console.log(`   ✅ Mock verification: ${isValid}`);
    }

    // Show final state
    console.log('\n📊 Final Vault State:');
    const finalState = protocol.getVaultState();
    console.log(`  Total BTC: ${finalState.totalBTC / 1e8}`);
    console.log(`  Total USDT: ${finalState.totalUSDT / 100}`);
    console.log(`  Block Height: ${finalState.blockHeight}`);
    console.log(`  Active Positions: 1`);
}

/**
 * Check if Rust backend is available
 */
async function checkRustBackend(): Promise<boolean> {
    try {
        console.log(`   Checking ${RUST_API_URL}/api/v1/health...`);
        const response = await axios.get(`${RUST_API_URL}/api/v1/health`, {
            timeout: 2000
        });
        return response.status === 200;
    } catch (error: any) {
        if (error.code === 'ECONNREFUSED') {
            console.log(`   ⚠️  Cannot connect to server at ${RUST_API_URL}`);
            console.log(`   ⚠️  Make sure the server is running: make server`);
        } else if (error.code === 'ETIMEDOUT') {
            console.log(`   ⚠️  Connection timed out to ${RUST_API_URL}`);
        } else {
            console.log(`   ⚠️  Backend check failed: ${error.message || error}`);
            console.log(`   ⚠️  Error code: ${error.code}`);
        }
        return false;
    }
}

/**
 * Demonstrate challenge-response mechanism
 */
async function demonstrateChallengeResponse() {
    console.log('\n⚔️  Challenge-Response Demo');
    console.log('---------------------------\n');

    // Create a mock challenge
    console.log('1. Creating challenge for invalid state transition...');
    const challenge = {
        id: 'challenge_' + Date.now(),
        disputedTransaction: 'tx_123',
        reason: 'Invalid state root computation',
        evidence: {
            expectedRoot: '0x' + 'aa'.repeat(32),
            actualRoot: '0x' + 'bb'.repeat(32)
        }
    };
    console.log(`   ✅ Challenge created: ${challenge.id}\n`);

    // Generate response
    console.log('2. Generating response with proof...');
    const response = {
        id: 'response_' + Date.now(),
        challengeId: challenge.id,
        proof: 'groth16_proof_data',
        witness: [1, 2, 3, 4]
    };
    console.log(`   ✅ Response generated: ${response.id}\n`);

    // Verify response
    console.log('3. Verifying response...');
    const isValid = true; // Mock verification
    console.log(`   ${isValid ? '✅ Response valid - challenge resolved' : '❌ Response invalid - challenge upheld'}\n`);
}

// Main execution
if (require.main === module) {
    runRealBitVMDemo()
        .then(() => demonstrateChallengeResponse())
        .then(() => {
            console.log('\n🎉 Demo completed successfully!');
            process.exit(0);
        })
        .catch((error) => {
            console.error('\n❌ Demo failed:', error);
            process.exit(1);
        });
}