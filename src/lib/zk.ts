import type { SudokuGrid } from './sudoku';

declare const snarkjs: SnarkJS;

interface Groth16Protocol {
	fullProve(input: ProofInput, wasmPath: string, zkeyPath: string): Promise<ProofResult>;
	verify(verificationKey: VerificationKey, publicSignals: string[], proof: ZkProof): Promise<boolean>;
}

interface ProofInput {
	puzzle: SudokuGrid;
	solution: SudokuGrid;
}

interface ProofResult {
	proof: ZkProof;
	publicSignals: string[];
}

interface SnarkJS {
	groth16: Groth16Protocol;
}

interface VerificationKey {
	curve: string;
	IC: string[][];
	nPublic: number;
	protocol: string;
	vk_alpha_1: string[];
	vk_alphabeta_12: string[][][];
	vk_beta_2: string[][];
	vk_delta_2: string[][];
	vk_gamma_2: string[][];
}

export interface ZkProof {
	curve: string;
	pi_a: string[];
	pi_b: string[][];
	pi_c: string[];
	protocol: string;
}

const ZK_ASSETS = {
	VERIFICATION_KEY: '/zk/verification_key.json',
	WASM: '/zk/sudoku.wasm',
	ZKEY: '/zk/sudoku_final.zkey'
} as const;

let verificationKeyCache: Promise<VerificationKey> | null = null;

const loadVerificationKey = (): Promise<VerificationKey> =>
	(verificationKeyCache ??= fetch(ZK_ASSETS.VERIFICATION_KEY).then((res) => {
		if (!res.ok) throw new Error('Failed to load verification key');
		return res.json();
	}));

const isValidZkProof = (value: unknown): value is ZkProof =>
	value !== null && typeof value === 'object' && 'pi_a' in value && 'pi_b' in value && 'pi_c' in value;

export const generateProof = async (puzzle: SudokuGrid, solution: SudokuGrid): Promise<ZkProof> => {
	const { proof } = await snarkjs.groth16.fullProve({ puzzle, solution }, ZK_ASSETS.WASM, ZK_ASSETS.ZKEY);
	return proof;
};

export const parseProof = (json: string): ZkProof | null => {
	try {
		const parsed: unknown = JSON.parse(json);
		return isValidZkProof(parsed) ? parsed : null;
	} catch {
		return null;
	}
};

export const serializeProof = (proof: ZkProof): string => JSON.stringify(proof, null, 2);

export const verifyProof = async (proof: ZkProof, puzzle: SudokuGrid): Promise<boolean> => {
	const verificationKey = await loadVerificationKey();
	const publicSignals = puzzle.flat().map(String);
	return snarkjs.groth16.verify(verificationKey, publicSignals, proof);
};
