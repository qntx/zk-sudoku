#!/bin/bash
# Generates and verifies a ZK proof for Sudoku.
# Usage: ./prove.sh [input.json]

set -e

CIRCUIT="sudoku"
BUILD="build"
INPUT=${1:-"input.json"}

# 1. Generate witness (use snarkjs to avoid ESM/CommonJS conflict)
echo "[1/3] Computing witness..."
snarkjs wtns calculate "$BUILD/${CIRCUIT}_js/$CIRCUIT.wasm" "$INPUT" "$BUILD/witness.wtns"

# 2. Generate proof
echo "[2/3] Generating proof..."
snarkjs groth16 prove "$BUILD/${CIRCUIT}_final.zkey" "$BUILD/witness.wtns" \
    "$BUILD/proof.json" "$BUILD/public.json"

# 3. Verify proof
echo "[3/3] Verifying proof..."
snarkjs groth16 verify "$BUILD/verification_key.json" "$BUILD/public.json" "$BUILD/proof.json"

# Cleanup
rm -f "$BUILD/witness.wtns"

echo "Output: $BUILD/proof.json, $BUILD/public.json"
