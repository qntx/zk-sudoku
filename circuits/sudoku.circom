pragma circom 2.1.6;

include "circomlib/circuits/comparators.circom";
include "circomlib/circuits/bitify.circom";

/*
 * RangeCheck1To9 - Asserts input is within [1, 9]
 * 
 * Constraints: in - 1 >= 0 AND 9 - in >= 0
 * Implementation: Bit decomposition ensures non-negative values
 */
template RangeCheck1To9() {
    signal input in;
    
    component lowerBound = Num2Bits(4);
    component upperBound = Num2Bits(4);
    
    lowerBound.in <== in - 1;
    upperBound.in <== 9 - in;
}

/*
 * AllDifferent9 - Asserts all 9 inputs are pairwise distinct
 * 
 * Constraints: C(9,2) = 36 pairwise inequality checks
 * Implementation: IsEqual(a,b) === 0 for all pairs
 */
template AllDifferent9() {
    signal input in[9];
    
    component isEq[36];
    var k = 0;
    
    for (var i = 0; i < 9; i++) {
        for (var j = i + 1; j < 9; j++) {
            isEq[k] = IsEqual();
            isEq[k].in[0] <== in[i];
            isEq[k].in[1] <== in[j];
            isEq[k].out === 0;
            k++;
        }
    }
}

/*
 * SudokuVerifier - Zero-knowledge Sudoku solution verifier
 * 
 * Public inputs:  puzzle[9][9]   - Sudoku puzzle (0 = empty cell)
 * Private inputs: solution[9][9] - Complete solution (values 1-9)
 * 
 * Constraints verified:
 *   1. Each cell value in [1, 9]
 *   2. Solution matches puzzle at given (non-zero) cells
 *   3. Each row contains 1-9 exactly once
 *   4. Each column contains 1-9 exactly once
 *   5. Each 3x3 box contains 1-9 exactly once
 */
template SudokuVerifier() {
    signal input puzzle[9][9];
    signal input solution[9][9];

    component rangeCheck[9][9];
    component rowCheck[9];
    component colCheck[9];
    component boxCheck[9];

    // Cell validation: range [1,9] and puzzle matching
    for (var i = 0; i < 9; i++) {
        for (var j = 0; j < 9; j++) {
            rangeCheck[i][j] = RangeCheck1To9();
            rangeCheck[i][j].in <== solution[i][j];
            
            // If puzzle[i][j] != 0, then solution must equal puzzle
            puzzle[i][j] * (solution[i][j] - puzzle[i][j]) === 0;
        }
    }

    // Row uniqueness
    for (var r = 0; r < 9; r++) {
        rowCheck[r] = AllDifferent9();
        for (var c = 0; c < 9; c++) {
            rowCheck[r].in[c] <== solution[r][c];
        }
    }

    // Column uniqueness
    for (var c = 0; c < 9; c++) {
        colCheck[c] = AllDifferent9();
        for (var r = 0; r < 9; r++) {
            colCheck[c].in[r] <== solution[r][c];
        }
    }

    // 3x3 box uniqueness
    for (var b = 0; b < 9; b++) {
        boxCheck[b] = AllDifferent9();
        var baseRow = (b \ 3) * 3;
        var baseCol = (b % 3) * 3;
        var idx = 0;
        for (var di = 0; di < 3; di++) {
            for (var dj = 0; dj < 3; dj++) {
                boxCheck[b].in[idx] <== solution[baseRow + di][baseCol + dj];
                idx++;
            }
        }
    }
}

component main {public [puzzle]} = SudokuVerifier();
