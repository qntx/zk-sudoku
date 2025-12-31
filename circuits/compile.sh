#!/bin/bash
# Compiles Sudoku ZK circuit and generates proving/verification keys.
# Usage: ./compile.sh

set -e

CIRCUIT="sudoku"
BUILD="build"
PTAU="powersOfTau28_hez_final_14.ptau"
PTAU_URL="https://storage.googleapis.com/zkevm/ptau/$PTAU"

mkdir -p "$BUILD"

# 1. Compile circuit
echo "[1/5] Compiling circuit..."
circom "$CIRCUIT.circom" --r1cs --wasm --sym -o "$BUILD"

# 2. Circuit info
echo "[2/5] Circuit info:"
snarkjs r1cs info "$BUILD/$CIRCUIT.r1cs"

# 3. Powers of Tau
if [ -f "$BUILD/$PTAU" ]; then
    echo "[3/5] Powers of Tau exists, skipping..."
else
    echo "[3/5] Downloading Powers of Tau..."
    curl -L -o "$BUILD/$PTAU" "$PTAU_URL"
fi

# 4. Groth16 setup
echo "[4/5] Generating proving key..."
snarkjs groth16 setup "$BUILD/$CIRCUIT.r1cs" "$BUILD/$PTAU" "$BUILD/${CIRCUIT}_0000.zkey"
snarkjs zkey contribute "$BUILD/${CIRCUIT}_0000.zkey" "$BUILD/${CIRCUIT}_final.zkey" \
    --name="dev" -v -e="$RANDOM"
rm -f "$BUILD/${CIRCUIT}_0000.zkey"

# 5. Export verification key
echo "[5/5] Exporting verification key..."
snarkjs zkey export verificationkey "$BUILD/${CIRCUIT}_final.zkey" "$BUILD/verification_key.json"

cat << EOF
Output in $BUILD/:
  - $CIRCUIT.r1cs          (constraints)
  - ${CIRCUIT}_js/         (WASM prover)
  - ${CIRCUIT}_final.zkey  (proving key)
  - verification_key.json  (verification key)
EOF
