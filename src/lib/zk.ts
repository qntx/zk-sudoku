import type { Grid } from './sudoku';

declare const snarkjs: {
	groth16: {
		fullProve(
			input: Record<string, unknown>,
			wasmPath: string,
			zkeyPath: string
		): Promise<{ proof: Proof; publicSignals: string[] }>;
		verify(vk: VerificationKey, publicSignals: string[], proof: Proof): Promise<boolean>;
	};
};

export interface Proof {
	pi_a: string[];
	pi_b: string[][];
	pi_c: string[];
	protocol: string;
	curve: string;
}

interface VerificationKey {
	protocol: string;
	curve: string;
	nPublic: number;
	vk_alpha_1: string[];
	vk_beta_2: string[][];
	vk_gamma_2: string[][];
	vk_delta_2: string[][];
	vk_alphabeta_12: string[][][];
	IC: string[][];
}

let vkCache: Promise<VerificationKey> | null = null;

const loadVerificationKey = (): Promise<VerificationKey> =>
	(vkCache ??= fetch('/zk/verification_key.json').then((r) => {
		if (!r.ok) throw new Error('Failed to load verification key');
		return r.json();
	}));

export const generateProof = async (puzzle: Grid, solution: Grid): Promise<Proof> => {
	const { proof } = await snarkjs.groth16.fullProve(
		{ puzzle, solution },
		'/zk/sudoku.wasm',
		'/zk/sudoku_final.zkey'
	);
	return proof;
};

export const verifyProof = async (proof: Proof, puzzle: Grid): Promise<boolean> =>
	snarkjs.groth16.verify(await loadVerificationKey(), puzzle.flat().map(String), proof);

export const proofToJson = (proof: Proof): string => JSON.stringify(proof, null, 2);

const isProof = (v: unknown): v is Proof =>
	!!v && typeof v === 'object' && 'pi_a' in v && 'pi_b' in v && 'pi_c' in v;

export const jsonToProof = (json: string): Proof | null => {
	try {
		const parsed: unknown = JSON.parse(json);
		return isProof(parsed) ? parsed : null;
	} catch {
		return null;
	}
};
