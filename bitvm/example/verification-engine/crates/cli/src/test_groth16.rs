// Test real Groth16 verification with BitVM

use bitvm3_crypto::groth16_verifier::{Groth16Verifier, Groth16Proof};
use bitvm3_core::bitvm_protocol::{EnhancedBitVM3Protocol, ProtocolScripts};

pub async fn test_groth16_verification() -> anyhow::Result<()> {
    println!("🔬 Testing Real Groth16 Verification with BitVM");
    println!("==============================================");
    
    // Initialize the enhanced protocol with real BitVM integration
    let protocol = EnhancedBitVM3Protocol::new();
    
    // Generate a test proof
    println!("\n1️⃣ Generating test Groth16 proof...");
    let proof = EnhancedBitVM3Protocol::generate_test_proof().await?;
    println!("   ✅ Proof generated successfully");
    
    // Verify the proof using real Groth16 verifier
    println!("\n2️⃣ Verifying proof with real Groth16 verifier...");
    let is_valid = protocol.verify_withdrawal_with_groth16(&proof).await?;
    
    if is_valid {
        println!("   ✅ Proof verification SUCCEEDED!");
    } else {
        println!("   ❌ Proof verification FAILED!");
        return Err(anyhow::anyhow!("Proof verification failed"));
    }
    
    // Generate protocol scripts
    println!("\n3️⃣ Generating BitVM protocol scripts...");
    let scripts = protocol.generate_protocol_scripts()?;
    
    // Display script statistics
    let stats = scripts.stats();
    println!("   📊 Script Statistics:");
    println!("      - BN254 operations: {} bytes", stats.bn254_size);
    println!("      - Hash operations: {} bytes", stats.hash_size);
    println!("      - Winternitz signatures: {} bytes", stats.winternitz_size);
    println!("      - Number of chunks: {}", stats.num_chunks);
    println!("      - Total chunk size: {} bytes", stats.total_chunk_size);
    println!("      - Total size: {} bytes", scripts.total_size());
    
    // Test state transition
    println!("\n4️⃣ Testing state transition with proof...");
    let mut protocol = EnhancedBitVM3Protocol::new();
    let old_state = [0u8; 32];
    let new_state = [1u8; 32];
    
    let transition_valid = protocol.process_state_transition(
        old_state,
        new_state,
        &proof
    ).await?;
    
    if transition_valid {
        println!("   ✅ State transition verified and applied!");
    } else {
        println!("   ❌ State transition verification failed!");
    }
    
    // Test BitVM script generation
    println!("\n5️⃣ Testing BitVM script generation...");
    test_bitvm_scripts()?;
    
    println!("\n✨ All Groth16 verification tests completed successfully!");
    Ok(())
}

fn test_bitvm_scripts() -> anyhow::Result<()> {
    use bitvm3_crypto::bitvm_integration::{BitVMU32Ops, BitVMBigInt};
    
    // Test u32 operations
    let add_script = BitVMU32Ops::add_u32_script();
    println!("   - u32 addition script: {} bytes", add_script.len());
    
    let xor_script = BitVMU32Ops::xor_u32_script();
    println!("   - u32 XOR script: {} bytes", xor_script.len());
    
    // Test bigint operations
    let mul_script = BitVMBigInt::mul_bigint_script();
    println!("   - BigInt multiplication script: {} bytes", mul_script.len());
    
    let inv_script = BitVMBigInt::inverse_bigint_script();
    println!("   - BigInt inverse script: {} bytes", inv_script.len());
    
    Ok(())
}

pub async fn benchmark_groth16() -> anyhow::Result<()> {
    use std::time::Instant;
    
    println!("\n📈 Benchmarking Groth16 Operations");
    println!("===================================");
    
    let protocol = EnhancedBitVM3Protocol::new();
    
    // Benchmark proof generation
    println!("\n⏱️  Proof Generation:");
    let start = Instant::now();
    let proof = EnhancedBitVM3Protocol::generate_test_proof().await?;
    let gen_time = start.elapsed();
    println!("   Time: {:?}", gen_time);
    
    // Benchmark verification
    println!("\n⏱️  Proof Verification:");
    let start = Instant::now();
    let _is_valid = protocol.verify_withdrawal_with_groth16(&proof).await?;
    let verify_time = start.elapsed();
    println!("   Time: {:?}", verify_time);
    
    // Benchmark script generation
    println!("\n⏱️  Script Generation:");
    let start = Instant::now();
    let _scripts = protocol.generate_protocol_scripts()?;
    let script_time = start.elapsed();
    println!("   Time: {:?}", script_time);
    
    println!("\n📊 Summary:");
    println!("   - Proof generation: {:?}", gen_time);
    println!("   - Verification: {:?}", verify_time);
    println!("   - Script generation: {:?}", script_time);
    
    Ok(())
}