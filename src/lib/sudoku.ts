import init, {
	Difficulty as WasmDifficulty,
	generateSudoku as wasmGenerateSudoku,
	validateSolution as wasmValidateSolution
} from '@pyroth/sodo';

export const BOX_SIZE = 3;
export const CELL_MAX = 9;
export const CELL_MIN = 0;
export const GRID_SIZE = 9;

export type DifficultyLevel = 'easy' | 'expert' | 'hard' | 'medium';
export type SudokuGrid = number[][];

export interface SudokuPuzzle {
	puzzle: SudokuGrid;
	solution: SudokuGrid;
}

const DIFFICULTY_MAP: Record<DifficultyLevel, WasmDifficulty> = {
	easy: WasmDifficulty.Easy,
	expert: WasmDifficulty.Expert,
	hard: WasmDifficulty.Hard,
	medium: WasmDifficulty.Medium
};

let wasmInitPromise: Promise<unknown> | null = null;

const ensureWasmInitialized = (): Promise<unknown> => (wasmInitPromise ??= init());

const isValidCellValue = (value: unknown): value is number =>
	typeof value === 'number' && value >= CELL_MIN && value <= CELL_MAX;

const isValidSudokuGrid = (value: unknown): value is SudokuGrid =>
	Array.isArray(value) &&
	value.length === GRID_SIZE &&
	value.every((row) => Array.isArray(row) && row.length === GRID_SIZE && row.every(isValidCellValue));

export const cloneGrid = (grid: SudokuGrid): SudokuGrid => grid.map((row) => [...row]);

export const createEmptyGrid = (): SudokuGrid =>
	Array.from({ length: GRID_SIZE }, () => Array<number>(GRID_SIZE).fill(CELL_MIN));

export const generateSudoku = async (difficulty: DifficultyLevel = 'medium'): Promise<SudokuPuzzle> => {
	await ensureWasmInitialized();
	return wasmGenerateSudoku(DIFFICULTY_MAP[difficulty]);
};

export const isGridEmpty = (grid: SudokuGrid): boolean =>
	grid.every((row) => row.every((cell) => cell === CELL_MIN));

export const parseGrid = (json: string): SudokuGrid | null => {
	try {
		const parsed: unknown = JSON.parse(json);
		return isValidSudokuGrid(parsed) ? parsed : null;
	} catch {
		return null;
	}
};

export const serializeGrid = (grid: SudokuGrid): string => JSON.stringify(grid, null, 2);

export const validateSolution = async (puzzle: SudokuGrid, solution: SudokuGrid): Promise<boolean> => {
	await ensureWasmInitialized();
	return wasmValidateSolution(puzzle, solution);
};
