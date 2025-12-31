<#
.SYNOPSIS
    Compiles Sudoku ZK circuit and generates proving/verification keys.
.DESCRIPTION
    1. Compile circom circuit to R1CS + WASM
    2. Download Powers of Tau (if needed)
    3. Generate Groth16 proving key
    4. Export verification key
.EXAMPLE
    .\compile.ps1
#>

$ErrorActionPreference = "Stop"

# Configuration
$Circuit = "sudoku"
$BuildDir = "build"
$PtauFile = "powersOfTau28_hez_final_14.ptau"
$PtauUrl = "https://storage.googleapis.com/zkevm/ptau/$PtauFile"

function Write-Step($step, $msg) { Write-Host "[$step] $msg" -ForegroundColor Yellow }
function Write-Done($msg) { Write-Host $msg -ForegroundColor Green }

Write-Host "`n=== Sudoku ZK Circuit Compilation ===`n" -ForegroundColor Cyan

# Setup
New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null

# 1. Compile circuit
Write-Step "1/5" "Compiling circuit..."
.\circom.exe "$Circuit.circom" --r1cs --wasm --sym -o $BuildDir

# 2. Circuit info
Write-Step "2/5" "Circuit info:"
snarkjs r1cs info "$BuildDir/$Circuit.r1cs"

# 3. Download Powers of Tau
$ptauPath = "$BuildDir/$PtauFile"
if (Test-Path $ptauPath) {
    Write-Step "3/5" "Powers of Tau exists, skipping..."
} else {
    Write-Step "3/5" "Downloading Powers of Tau..."
    Invoke-WebRequest -Uri $PtauUrl -OutFile $ptauPath
}

# 4. Generate zkey (Groth16)
Write-Step "4/5" "Generating proving key..."
snarkjs groth16 setup "$BuildDir/$Circuit.r1cs" $ptauPath "$BuildDir/${Circuit}_0000.zkey"
snarkjs zkey contribute "$BuildDir/${Circuit}_0000.zkey" "$BuildDir/${Circuit}_final.zkey" `
    --name="dev" -v -e="$(Get-Random)"
Remove-Item "$BuildDir/${Circuit}_0000.zkey" -ErrorAction SilentlyContinue

# 5. Export verification key
Write-Step "5/5" "Exporting verification key..."
snarkjs zkey export verificationkey "$BuildDir/${Circuit}_final.zkey" "$BuildDir/verification_key.json"

Write-Done "`n=== Build Complete ==="
Write-Host @"
Output in $BuildDir/:
  - $Circuit.r1cs          (constraints)
  - ${Circuit}_js/         (WASM prover)
  - ${Circuit}_final.zkey  (proving key)
  - verification_key.json  (verification key)
"@
