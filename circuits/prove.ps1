<#
.SYNOPSIS
    Generates and verifies a ZK proof for Sudoku.
.PARAMETER InputFile
    Path to input JSON containing puzzle and solution.
.EXAMPLE
    .\prove.ps1 input.json
#>

param([string]$InputFile = "input.json")

$ErrorActionPreference = "Stop"

# Configuration
$Circuit = "sudoku"
$BuildDir = "build"

function Write-Step($step, $msg) { Write-Host "[$step] $msg" -ForegroundColor Yellow }
function Write-Done($msg) { Write-Host $msg -ForegroundColor Green }

Write-Host "`n=== Sudoku ZK Proof Generation ===" -ForegroundColor Cyan
Write-Host "Input: $InputFile`n"

# 1. Generate witness (use snarkjs to avoid ESM/CommonJS conflict)
Write-Step "1/3" "Computing witness..."
snarkjs wtns calculate "$BuildDir/${Circuit}_js/$Circuit.wasm" $InputFile "$BuildDir/witness.wtns"

# 2. Generate proof
Write-Step "2/3" "Generating proof..."
snarkjs groth16 prove "$BuildDir/${Circuit}_final.zkey" "$BuildDir/witness.wtns" `
    "$BuildDir/proof.json" "$BuildDir/public.json"

# 3. Verify proof
Write-Step "3/3" "Verifying proof..."
snarkjs groth16 verify "$BuildDir/verification_key.json" "$BuildDir/public.json" "$BuildDir/proof.json"

# Cleanup
Remove-Item "$BuildDir/witness.wtns" -ErrorAction SilentlyContinue

Write-Done "`n=== Proof Generated ==="
Write-Host "Output: $BuildDir/proof.json, $BuildDir/public.json"
