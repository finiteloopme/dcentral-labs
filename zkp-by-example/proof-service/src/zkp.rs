//! This module contains the Zero-Knowledge Proof logic for the Sudoku game.

use ark_bls12_381::{Bls12_381, Fr};
use ark_groth16::{Groth16, Proof, ProvingKey, VerifyingKey};
use ark_r1cs_std::prelude::*;
use ark_r1cs_std::fields::fp::FpVar;
use ark_relations::r1cs::{ConstraintSynthesizer, ConstraintSystemRef, SynthesisError};
use ark_snark::{SNARK, CircuitSpecificSetupSNARK};
use ark_std::rand::rngs::StdRng;
use ark_std::rand::SeedableRng;
use tracing::info;

/// The Sudoku circuit.
///
/// This circuit checks that the score for a given Sudoku board is calculated correctly.
#[derive(Clone)]
pub struct SudokuCircuit {
    /// The player's submitted Sudoku board (private input).
    pub player_board: Vec<Vec<Option<u8>>>,
    /// The solution board (private input).
    pub solution_board: Vec<Vec<Option<u8>>>,
    /// The claimed score (public input).
    pub score: i32,
    /// The hash of the solution board (public input).
    pub solution_hash: Fr,
}

impl ConstraintSynthesizer<Fr> for SudokuCircuit {
    /// Generates the constraints for the Sudoku scoring circuit.
    fn generate_constraints(self, cs: ConstraintSystemRef<Fr>) -> Result<(), SynthesisError> {
        // 1. Allocate public inputs.
        let score_var = FpVar::<Fr>::new_input(cs.clone(), || Ok(Fr::from(self.score as u64)))?;
        let _solution_hash_var = FpVar::<Fr>::new_input(cs.clone(), || Ok(self.solution_hash))?;

        // 2. Allocate private inputs.
        let player_board_vars = self
            .player_board
            .iter()
            .map(|row| {
                row.iter()
                    .map(|cell|
                        FpVar::<Fr>::new_witness(cs.clone(), || Ok(Fr::from(cell.unwrap_or(0) as u64)))
                    )
                    .collect::<Result<Vec<_>, _>>()
            })
            .collect::<Result<Vec<_>, _>>()?;

        let solution_board_vars = self
            .solution_board
            .iter()
            .map(|row| {
                row.iter()
                    .map(|cell|
                        FpVar::<Fr>::new_witness(cs.clone(), || Ok(Fr::from(cell.unwrap_or(0) as u64)))
                    )
                    .collect::<Result<Vec<_>, _>>()
            })
            .collect::<Result<Vec<_>, _>>()?;

        // 3. Score Calculation Constraint.
        let mut calculated_score = FpVar::<Fr>::zero();
        let one = FpVar::<Fr>::one();

        for i in 0..9 {
            for j in 0..9 {
                let player_move_is_some = self.player_board[i][j].is_some();
                let player_move_is_some_var = Boolean::new_witness(cs.clone(), || Ok(player_move_is_some))?;

                let is_correct = player_board_vars[i][j].is_eq(&solution_board_vars[i][j])?;

                let score_change = is_correct.select(&one, &FpVar::zero())?;
                let final_score_change = player_move_is_some_var.select(&score_change, &FpVar::zero())?;

                calculated_score += final_score_change;
            }
        }

        calculated_score.enforce_equal(&score_var)?;

        // 4. Board Validity Constraints.
        enforce_board_validity(cs.clone(), &player_board_vars)?;
        enforce_board_validity(cs.clone(), &solution_board_vars)?;

        // 5. Solution Hash Constraint.
        // (Skipped for now)

        Ok(())
    }
}

/// Enforces that a given 9x9 board is a valid Sudoku board.
fn enforce_board_validity(cs: ConstraintSystemRef<Fr>, board: &Vec<Vec<FpVar<Fr>>>) -> Result<(), SynthesisError> {
    // Check rows and columns.
    for i in 0..9 {
        let mut row = Vec::new();
        let mut col = Vec::new();
        for j in 0..9 {
            row.push(board[i][j].clone());
            col.push(board[j][i].clone());
        }
        enforce_set_is_valid(cs.clone(), &row)?;
        enforce_set_is_valid(cs.clone(), &col)?;
    }

    // Check 3x3 squares.
    for i in (0..9).step_by(3) {
        for j in (0..9).step_by(3) {
            let mut square = Vec::new();
            for row in &board[i..i + 3] {
                for cell in &row[j..j + 3] {
                    square.push(cell.clone());
                }
            }
            enforce_set_is_valid(cs.clone(), &square)?;
        }
    }

    Ok(())
}

/// Enforces that a set of 9 cells contains the numbers from 1 to 9 exactly once.
/// (Ignoring zeros, which represent empty cells).
fn enforce_set_is_valid(_cs: ConstraintSystemRef<Fr>, set: &[FpVar<Fr>]) -> Result<(), SynthesisError> {
    // This is a complex constraint to implement efficiently.
    // A simple way is to check that all non-zero elements are unique.
    // For each pair of non-zero cells (a, b), enforce that a != b.
    for i in 0..9 {
        for j in i + 1..9 {
            let a = &set[i];
            let b = &set[j];

            // Check if either a or b is zero.
            let a_is_zero = a.is_zero()?;
            let b_is_zero = b.is_zero()?;
            let either_is_zero = a_is_zero.or(&b_is_zero)?;

            // If neither is zero, they must not be equal.
            let are_equal = a.is_eq(b)?;
            either_is_zero.or(&are_equal.not())?.enforce_equal(&Boolean::TRUE)?;
        }
    }
    Ok(())
}


/// Generates a proof for the Sudoku circuit.
pub fn generate_proof(
    circuit: SudokuCircuit,
) -> (Proof<Bls12_381>, ProvingKey<Bls12_381>, VerifyingKey<Bls12_381>) {
    info!("Generating setup parameters...");
    let mut rng = StdRng::seed_from_u64(0u64);
    let (pk, vk) = Groth16::<Bls12_381>::setup(circuit.clone(), &mut rng).unwrap();
    info!("Setup parameters generated.");

    info!("Creating proof...");
    let proof = Groth16::<Bls12_381>::prove(&pk, circuit, &mut rng).unwrap();
    info!("Proof created.");

    (proof, pk, vk)
}

/// Verifies a proof for the Sudoku circuit.
pub fn verify_proof(
    vk: &VerifyingKey<Bls12_381>,
    proof: &Proof<Bls12_381>,
    public_inputs: &[Fr],
) -> bool {
    info!("Verifying proof...");
    let result = Groth16::<Bls12_381>::verify(vk, public_inputs, proof).unwrap();
    info!("Proof verification result: {}", result);
    result
}
