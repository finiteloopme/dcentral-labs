use std::time::Instant;
use std::fs::File;
use std::io::BufReader;
use proof_service::{SudokuCircuit};
use halo2_proofs::{
    plonk::{create_proof, keygen_pk, keygen_vk, verify_proof, VerifyingKey, ProvingKey},
    poly::commitment::Params,
    transcript::{Blake2bWrite, Blake2bRead, Challenge255},
    pasta::EqAffine,
};
use rand::rngs::OsRng;
use serde::Deserialize;

#[derive(Deserialize)]
struct GenerateProofRequest {
    player_board: [[Option<u8>; 9]; 9],
    solution_board: [[Option<u8>; 9]; 9],
}

#[test]
fn run_benchmarks() {
    println!("Running benchmarks...");

    let file = File::open("dummy-proof-request.json").expect("file should open");
    let reader = BufReader::new(file);
    let proof_request: GenerateProofRequest = serde_json::from_reader(reader).expect("should deserialize");

    let params: Params<EqAffine> = Params::new(13);
    let empty_circuit = SudokuCircuit::default();
    let vk = keygen_vk(&params, &empty_circuit).expect("keygen_vk should not fail");
    let pk = keygen_pk(&params, vk.clone(), &empty_circuit).expect("keygen_pk should not fail");

    benchmark_case("Sudoku Circuit with dummy data", proof_request, &params, &pk, &vk);
}

fn benchmark_case(name: &str, proof_request: GenerateProofRequest, params: &Params<EqAffine>, pk: &ProvingKey<EqAffine>, vk: &VerifyingKey<EqAffine>) {
    println!("\n--- {} ---", name);

    let mut solution_board = [[0u8; 9]; 9];
    for i in 0..9 {
        for j in 0..9 {
            solution_board[i][j] = proof_request.solution_board[i][j].unwrap_or(0);
        }
    }

    let circuit = SudokuCircuit {
        player_board: proof_request.player_board,
        solution_board,
    };

    // Benchmark proof generation
    let start_generation = Instant::now();
    let mut transcript = Blake2bWrite::<_, _, Challenge255<_>>::init(vec![]);
    create_proof(params, pk, &[circuit], &[&[]], OsRng, &mut transcript)
        .expect("proof generation should not fail");
    let proof = transcript.finalize();
    let generation_time = start_generation.elapsed();
    println!("Proof generation time: {:?}", generation_time);

    // Benchmark proof verification
    let start_verification = Instant::now();
    let mut transcript = Blake2bRead::<_, _, Challenge255<_>>::init(&proof[..]);
    let strategy = halo2_proofs::plonk::SingleVerifier::new(params);
    verify_proof(
        params,
        vk,
        strategy,
        &[&[]],
        &mut transcript,
    )
    .expect("proof verification should not fail");
    let verification_time = start_verification.elapsed();
    println!("Proof verification time: {:?}", verification_time);
}