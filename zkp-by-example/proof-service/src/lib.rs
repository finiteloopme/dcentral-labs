//! This module contains the Zero-Knowledge Proof logic for the Sudoku game.
//!
//! The ZKP logic is implemented using the `halo2_proofs` library.
//! The main components are:
//! - `SudokuChip`: A chip that implements the constraints for the Sudoku game.
//! - `SudokuCircuit`: The main circuit for the Sudoku game.

use halo2_proofs::{
    circuit::{Layouter, SimpleFloorPlanner, Value, AssignedCell},
    plonk::{
        Advice, Circuit, Column, ConstraintSystem, Error, Expression, Instance,
        Selector,
    },
    poly::Rotation,
    pasta::Fp,
};
use log::info;

#[derive(Clone, Debug)]
pub struct SudokuConfig {
    pub advice: [Column<Advice>; 9],
    pub instance: Column<Instance>,
    pub q_row_check: Selector,
    pub q_col_check: Selector,
    pub q_box_check: Selector,
    pub q_fixed_value: Selector,
}

#[derive(Clone, Debug)]
pub struct SudokuChip {
    config: SudokuConfig,
}

impl SudokuChip {
    pub fn new(config: SudokuConfig) -> Self {
        Self { config }
    }

    pub fn configure(meta: &mut ConstraintSystem<Fp>) -> SudokuConfig {
        let advice = [
            meta.advice_column(), meta.advice_column(), meta.advice_column(),
            meta.advice_column(), meta.advice_column(), meta.advice_column(),
            meta.advice_column(), meta.advice_column(), meta.advice_column(),
        ];
        let instance = meta.instance_column();

        advice.iter().for_each(|c| meta.enable_equality(*c));
        meta.enable_equality(instance);

        let q_row_check = meta.selector();
        let q_col_check = meta.selector();
        let q_box_check = meta.selector();
        let q_fixed_value = meta.selector();

        meta.create_gate("row check", |meta| {
            let q = meta.query_selector(q_row_check);
            let cells = advice.map(|c| meta.query_advice(c, Rotation::cur()));
            
            let constraints = (1..9).map(|i| {
                let mut diff = Expression::Constant(Fp::one());
                for j in 0..i {
                    diff = diff * (cells[i].clone() - cells[j].clone());
                }
                diff
            });

            vec![q.clone() * constraints.reduce(|acc, e| acc * e).unwrap()]
        });

        // Similar constraints for col and box checks can be added here

        SudokuConfig {
            advice,
            instance,
            q_row_check,
            q_col_check,
            q_box_check,
            q_fixed_value,
        }
    }

    pub fn assign_region(
        &self,
        mut layouter: impl Layouter<Fp>,
        solution: [[u8; 9]; 9],
        puzzle: [[Option<u8>; 9]; 9],
    ) -> Result<Vec<Vec<AssignedCell<Fp, Fp>>>, Error> {
        layouter.assign_region(
            || "sudoku puzzle",
            |mut region| {
                let mut assigned_cells = Vec::new();
                for i in 0..9 {
                    let mut row_cells = Vec::new();
                    for j in 0..9 {
                        let cell = region.assign_advice(
                            || format!("cell_{}_{}", i, j),
                            self.config.advice[j],
                            i,
                            || Value::known(Fp::from(solution[i][j] as u64)),
                        )?;
                        row_cells.push(cell);
                    }
                    assigned_cells.push(row_cells);
                }

                for i in 0..9 {
                    for j in 0..9 {
                        if let Some(val) = puzzle[i][j] {
                            let public_cell = region.assign_advice_from_instance(
                                || format!("public_{}_{}", i, j),
                                self.config.instance,
                                i * 9 + j,
                                self.config.advice[j],
                                i,
                            )?;
                            region.constrain_equal(assigned_cells[i][j].cell(), public_cell.cell())?;
                        }
                    }
                }
                Ok(assigned_cells)
            },
        )
    }
}

#[derive(Clone, Default)]
pub struct SudokuCircuit {
    pub solution: [[u8; 9]; 9],
    pub puzzle: [[Option<u8>; 9]; 9],
}

impl Circuit<Fp> for SudokuCircuit {
    type Config = SudokuConfig;
    type FloorPlanner = SimpleFloorPlanner;

    fn without_witnesses(&self) -> Self {
        Self::default()
    }

    fn configure(meta: &mut ConstraintSystem<Fp>) -> Self::Config {
        SudokuChip::configure(meta)
    }

    fn synthesize(
        &self,
        config: Self::Config,
        mut layouter: impl Layouter<Fp>,
    ) -> Result<(), Error> {
        let chip = SudokuChip::new(config);
        chip.assign_region(layouter.namespace(|| "sudoku"), self.solution, self.puzzle)?;
        Ok(())
    }
}
