<#
.SYNOPSIS
    Compiles Sudoku ZK circuit and generates Groth16 proving/verification keys.
.EXAMPLE
    .\compile.ps1
#>

$ErrorActionPreference = "Stop"

$Circuit = "sudoku"
$Build = "build"
$Ptau = "powersOfTau28_hez_final_14.ptau"

function Step($n, $msg) { Write-Host "[$n] $msg" -ForegroundColor Yellow }

New-Item -ItemType Directory -Path $Build -Force | Out-Null

# 1. circom compiler
if (Test-Path ".\circom.exe") {
    Step "1/5" "circom.exe exists"
} else {
    Step "1/5" "Downloading circom..."
    $ver = (Invoke-RestMethod "https://api.github.com/repos/iden3/circom/releases/latest").tag_name
    Invoke-WebRequest "https://github.com/iden3/circom/releases/download/$ver/circom-windows-amd64.exe" -OutFile ".\circom.exe"
    Write-Host "  circom $ver" -ForegroundColor DarkGray
}

# 2. Compile circuit
Step "2/5" "Compiling circuit..."
.\circom.exe "$Circuit.circom" --r1cs --wasm --sym -o $Build
snarkjs r1cs info "$Build/$Circuit.r1cs"

# 3. Powers of Tau
$ptauPath = "$Build/$Ptau"
if (Test-Path $ptauPath) {
    Step "3/5" "Powers of Tau exists"
} else {
    Step "3/5" "Downloading Powers of Tau..."
    Invoke-WebRequest "https://storage.googleapis.com/zkevm/ptau/$Ptau" -OutFile $ptauPath
}

# 4. Groth16 setup
Step "4/5" "Generating proving key..."
snarkjs groth16 setup "$Build/$Circuit.r1cs" $ptauPath "$Build/${Circuit}_0.zkey"
snarkjs zkey contribute "$Build/${Circuit}_0.zkey" "$Build/${Circuit}_final.zkey" --name="dev" -v -e="$(Get-Random)"
Remove-Item "$Build/${Circuit}_0.zkey" -ErrorAction SilentlyContinue

# 5. Export verification key
Step "5/5" "Exporting verification key..."
snarkjs zkey export verificationkey "$Build/${Circuit}_final.zkey" "$Build/verification_key.json"

Write-Host "Output: $Build/{$Circuit.r1cs, ${Circuit}_js/, ${Circuit}_final.zkey, verification_key.json}"
