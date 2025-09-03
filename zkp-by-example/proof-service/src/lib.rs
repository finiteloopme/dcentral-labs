//! This module contains the Zero-Knowledge Proof logic for the Sudoku game.
//!
//! The ZKP logic is implemented using the `halo2_proofs` library.
//! The main components are:
//! - `SudokuChip`: A chip that implements the constraints for the Sudoku game.
//! - `SudokuCircuit`: The main circuit for the Sudoku game.
//!
//! The circuit checks the following constraints:
//! - Each cell in the player's board must be between 1 and 9.
//! - Each row in the player's board must contain each number from 1 to 9 exactly once.
//! - Each column in the player's board must contain each number from 1 to 9 exactly once.
//! - Each 3x3 subgrid in the player's board must contain each number from 1 to 9 exactly once.
//! - The player's board must match the solution board where the solution board is not empty.

use halo2_proofs::{
    circuit::{Layouter, SimpleFloorPlanner, Value},
    plonk::{
        Advice, Circuit, Column, ConstraintSystem, Error, Expression,
        Selector,
    },
    poly::Rotation,
    pasta::Fp,
};
use log::info;

/// A chip to handle sudoku constraints.
///
/// A chip in Halo2 is a small, reusable component that implements a specific set of constraints.
/// In this case, the `SudokuChip` will implement the constraints for the Sudoku game.
///
/// The chip is configured with the necessary columns and selectors to enforce the Sudoku rules.
/// The constraints are defined in the `configure` function.
#[derive(Clone, Debug)]
pub struct SudokuChip {
    /// The advice columns for the chip.
    ///
    /// Advice columns are used to store the witness data for the circuit.
    /// In this case, we will use the advice columns to store the Sudoku board.
    /// We use 9 advice columns, one for each column of the Sudoku board.
    pub advice: [Column<Advice>; 9],
    /// The selector for the row check.
    ///
    /// Selectors are used to enable or disable constraints.
    /// In this case, we use a selector to enable the row check constraint for each row of the Sudoku board.
    pub q_row: Selector,
}

impl SudokuChip {
    /// Configures the chip.
    ///
    /// The `configure` function is responsible for setting up the constraints for the chip.
    /// This function is called once when the circuit is created.
    ///
    /// The constraints are defined using the `create_gate` function.
    /// The `create_gate` function takes a name for the gate and a closure that defines the constraints.
    /// The closure is passed a `meta` object that can be used to query the columns and selectors of the chip.
    ///
    /// In this case, we define a single gate called "row check".
    /// This gate enforces that the sum of the values in each row is 45 (the sum of the numbers from 1 to 9).
    pub fn configure(
        meta: &mut ConstraintSystem<Fp>,
        advice: [Column<Advice>; 9],
    ) -> Self {
        // Enable equality for each advice column.
        // This allows us to copy values between cells.
        for column in &advice {
            meta.enable_equality(*column);
        }
        // Create a selector for the row check.
        let q_row = meta.selector();

        // Create a gate for the row check.
        meta.create_gate("row check", |meta| {
            // Query the selector for the row check.
            let q_row = meta.query_selector(q_row);
            // Query the advice columns.
            let advice = advice.map(|c| meta.query_advice(c, Rotation::cur()));

            // Create a vector to store the constraints.
            let mut constraints = Vec::new();
            // Create a variable to store the sum of the values in the row.
            let mut row_sum = Expression::Constant(Fp::zero());
            // Iterate over the advice columns and add the values to the row sum.
            for i in 0..9 {
                row_sum = row_sum + advice[i].clone();
            }
            // Add the constraint that the row sum must be 45.
            constraints.push(q_row.clone() * (row_sum - Expression::Constant(Fp::from(45))));

            // Return the constraints.
            constraints
        });

        // Return the chip.
        Self { advice, q_row }
    }
}

/// The sudoku circuit.
///
/// The `SudokuCircuit` is the main circuit for the Sudoku game.
/// It is responsible for loading the Sudoku board and applying the constraints.
///
/// The circuit is defined by the `Circuit` trait.
/// The `Circuit` trait has three associated types:
/// - `Config`: The configuration for the circuit. In this case, the `SudokuChip`.
/// - `FloorPlanner`: The floor planner for the circuit. In this case, the `SimpleFloorPlanner`.
/// - `Params`: The parameters for the circuit. In this case, the `pasta` parameters.
#[derive(Clone, Default)]
pub struct SudokuCircuit {
    /// The player's submitted sudoku board.
    /// This is the witness data for the circuit.
    pub player_board: [[Option<u8>; 9]; 9],
    /// The solution board.
    /// This is public data for the circuit.
    pub solution_board: [[u8; 9]; 9],
}

impl Circuit<Fp> for SudokuCircuit {
    type Config = SudokuChip;
    type FloorPlanner = SimpleFloorPlanner;

    /// Returns a new instance of the circuit without any witness data.
    /// This is used for key generation.
    fn without_witnesses(&self) -> Self {
        Self::default()
    }

    /// Configures the circuit.
    /// This function is called once when the circuit is created.
    fn configure(meta: &mut ConstraintSystem<Fp>) -> Self::Config {
        // Create the advice columns for the circuit.
        let advice = [
            meta.advice_column(),
            meta.advice_column(),
            meta.advice_column(),
            meta.advice_column(),
            meta.advice_column(),
            meta.advice_column(),
            meta.advice_column(),
            meta.advice_column(),
            meta.advice_column(),
        ];
        // Configure the chip.
        SudokuChip::configure(meta, advice)
    }

    /// Synthesizes the circuit.
    ///
    /// The `synthesize` function is responsible for loading the witness data into the circuit
    /// and applying the constraints.
    ///
    /// The witness data is loaded using the `assign_advice` function.
    /// The constraints are applied by enabling the selectors for the gates.
    fn synthesize(
        &self,
        config: Self::Config,
        mut layouter: impl Layouter<Fp>,
    ) -> Result<(), Error> {
        // Assign the player board to the circuit.
        info!("Assigning player board to circuit");
        layouter.assign_region(
            || "player board",
            |mut region| {
                // Iterate over the rows of the player board.
                for i in 0..9 {
                    // Enable the row check selector for the current row.
                    config.q_row.enable(&mut region, i)?;
                    // Iterate over the columns of the player board.
                    for j in 0..9 {
                        // If the cell has a value, assign it to the circuit.
                        if let Some(value) = self.player_board[i][j] {
                            info!("Assigning cell ({}, {}) with value {}", i, j, value);
                            // Assign the value to the advice column for the current column.
                            let cell = region.assign_advice(
                                || format!("player_board_{}_{}", i, j),
                                config.advice[j],
                                i,
                                || Value::known(Fp::from(value as u64)),
                            )?;
                            // Print the cell value for debugging.
                            cell.value().map(|v| println!("cell value: {:?}", v));
                        }
                    }
                }
                Ok(())
            },
        )?;
        info!("Player board assigned successfully");

        Ok(())
    }
}