interface SudokuGridProps {
  /**
   * The Sudoku board to display.
   */
  board: (number | null)[][];
  /**
   * The initial Sudoku board.
   */
  initialBoard: (number | null)[][];
  /**
   * A callback function that is called when a cell value changes.
   */
  onCellChange: (row: number, col: number, value: number | null) => void;
}

/**
 * A component that displays the Sudoku grid.
 *
 * The grid is interactive, allowing users to enter numbers into the cells.
 */
function SudokuGrid({ board, initialBoard, onCellChange }: SudokuGridProps) {
  /**
   * Handles changes to a cell's value.
   *
   * This function is called when the user types in a cell.
   * It parses the input and calls the onCellChange callback.
   */
  const handleChange = (row: number, col: number, value: string) => {
    const num = value === '' ? null : parseInt(value, 10);
    // Basic validation to ensure the number is between 1 and 9.
    if (num === null || (num >= 1 && num <= 9)) {
      onCellChange(row, col, num);
    }
  };

  return (
    <div className="sudoku-grid">
      {board.map((row, rowIndex) => (
        <div key={rowIndex} className="sudoku-row">
          {row.map((cell, colIndex) => {
            const isInitial = initialBoard[rowIndex][colIndex] !== null;
            const className = `sudoku-cell ${isInitial ? 'initial-cell' : 'user-cell'}`;
            return (
              <input
                key={colIndex}
                type="number"
                min="1"
                max="9"
                value={cell || ''}
                onChange={e => handleChange(rowIndex, colIndex, e.target.value)}
                className={className}
                readOnly={isInitial}
              />
            );
          })}
        </div>
      ))}
    </div>
  );
}

export default SudokuGrid;
