# ZK Sudoku

Prove you solved a Sudoku puzzle without revealing the solution.

## Overview

ZK Sudoku demonstrates zero-knowledge proofs in an interactive web application. Using the Groth16 protocol on the BN128 curve, it enables:

- **Generate** — Create Sudoku puzzles with adjustable difficulty
- **Prove** — Generate a cryptographic proof that you know the solution
- **Verify** — Validate proofs without seeing the actual solution

## Tech Stack

| Layer           | Technology       |
|-----------------|------------------|
| Circuit         | Circom2          |
| Proving System  | Groth16 / snarkjs|

## Circuit

The Sudoku circuit verifies:

1. Solution contains digits 1-9 in each row, column, and 3×3 box
2. Solution matches the given puzzle clues

Compile circuits:

```bash
cd circuits
./compile.sh   # Unix
./compile.ps1  # Windows
```

## Development

```bash
# Install dependencies
bun install

# Start dev server
bun run dev
```

## License

BSD-3-Clause
