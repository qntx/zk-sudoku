import init, {
	Difficulty as SodoDifficulty,
	generateSudoku as sodoGenerate,
	validateSolution as sodoValidate
} from '@pyroth/sodo';

export type Grid = number[][];
export type Difficulty = 'easy' | 'medium' | 'hard' | 'expert';

const DIFFICULTY_MAP: Record<Difficulty, SodoDifficulty> = {
	easy: SodoDifficulty.Easy,
	medium: SodoDifficulty.Medium,
	hard: SodoDifficulty.Hard,
	expert: SodoDifficulty.Expert
};

let initPromise: Promise<unknown> | null = null;

const ensureInit = () => (initPromise ??= init());

export const createEmptyGrid = (): Grid =>
	Array.from({ length: 9 }, () => Array<number>(9).fill(0));

export const cloneGrid = (grid: Grid): Grid => grid.map((row) => [...row]);

export const generateSudoku = async (
	difficulty: Difficulty = 'medium'
): Promise<{ puzzle: Grid; solution: Grid }> => {
	await ensureInit();
	return sodoGenerate(DIFFICULTY_MAP[difficulty]);
};

export const validateSolution = async (puzzle: Grid, solution: Grid): Promise<boolean> => {
	await ensureInit();
	return sodoValidate(puzzle, solution);
};

export const gridToJson = (grid: Grid): string => JSON.stringify(grid, null, 2);

const isValidCell = (v: unknown): v is number => typeof v === 'number' && v >= 0 && v <= 9;

const isGrid = (v: unknown): v is Grid =>
	Array.isArray(v) &&
	v.length === 9 &&
	v.every((row) => Array.isArray(row) && row.length === 9 && row.every(isValidCell));

export const jsonToGrid = (json: string): Grid | null => {
	try {
		const parsed: unknown = JSON.parse(json);
		return isGrid(parsed) ? parsed : null;
	} catch {
		return null;
	}
};

export const isEmptyGrid = (grid: Grid): boolean =>
	grid.every((row) => row.every((cell) => cell === 0));
