<script lang="ts">
	import { BOX_SIZE, GRID_SIZE, type SudokuGrid } from '$lib/sudoku';

	interface Props {
		editable?: boolean;
		grid: SudokuGrid;
		onCellChange?: (row: number, col: number, value: number) => void;
		puzzle?: SudokuGrid;
		showSolution?: boolean;
	}

	const { editable = false, grid, onCellChange, puzzle, showSolution = false }: Props = $props();

	const LAST_INDEX = GRID_SIZE - 1;

	const isGivenCell = (row: number, col: number): boolean => puzzle?.[row][col] !== 0;

	const isBoxBottomBoundary = (row: number): boolean =>
		row % BOX_SIZE === BOX_SIZE - 1 && row !== LAST_INDEX;

	const isBoxRightBoundary = (col: number): boolean =>
		col % BOX_SIZE === BOX_SIZE - 1 && col !== LAST_INDEX;

	const getCellStateClass = (row: number, col: number): string => {
		if (isGivenCell(row, col)) return 'given';
		const cellValue = grid[row][col];
		if (cellValue === 0) return '';
		return showSolution ? 'solved' : 'user-input';
	};

	const computeCellClasses = (row: number, col: number): string =>
		[
			'cell',
			isBoxBottomBoundary(row) && 'box-bottom',
			isBoxRightBoundary(col) && 'box-right',
			getCellStateClass(row, col)
		]
			.filter(Boolean)
			.join(' ');

	const handleCellInput = (
		row: number,
		col: number,
		event: Event & { currentTarget: HTMLInputElement }
	): void => {
		const inputValue = event.currentTarget.value;

		if (!inputValue) {
			onCellChange?.(row, col, 0);
			return;
		}

		const lastDigit = parseInt(inputValue.slice(-1), 10);
		const isValidDigit = lastDigit >= 1 && lastDigit <= GRID_SIZE;

		if (isValidDigit) {
			onCellChange?.(row, col, lastDigit);
			event.currentTarget.value = String(lastDigit);
		} else {
			const currentValue = grid[row][col];
			event.currentTarget.value = currentValue ? String(currentValue) : '';
		}
	};
</script>

<div class="board-wrapper">
	<div class="board">
		{#each grid as row, rowIndex}
			{#each row as cellValue, colIndex}
				<div class={computeCellClasses(rowIndex, colIndex)}>
					{#if editable && !isGivenCell(rowIndex, colIndex)}
						<input
							type="text"
							inputmode="numeric"
							value={cellValue || ''}
							oninput={(event) => handleCellInput(rowIndex, colIndex, event)}
							class="cell-input"
						/>
					{:else}
						<span class="cell-value">{cellValue || ''}</span>
					{/if}
				</div>
			{/each}
		{/each}
	</div>
</div>

<style>
	.board-wrapper {
		animation: scaleIn var(--duration-slow) var(--ease-out);
		background: linear-gradient(145deg, var(--color-slate-50), var(--color-slate-100));
		border-radius: var(--radius-2xl);
		box-shadow:
			var(--shadow-lg),
			0 0 0 1px var(--color-slate-200);
		max-width: 540px;
		padding: var(--space-4);
		width: 100%;
	}

	.board {
		aspect-ratio: 1;
		background: white;
		border: 2px solid var(--color-slate-700);
		border-radius: var(--radius-lg);
		display: grid;
		grid-template-columns: repeat(9, 1fr);
		overflow: hidden;
		width: 100%;
	}

	.cell {
		align-items: center;
		aspect-ratio: 1;
		background: white;
		border: 1px solid var(--color-slate-200);
		display: flex;
		justify-content: center;
		position: relative;
		transition: background var(--duration-fast) var(--ease-out);
	}

	.cell:hover {
		background: var(--color-slate-50);
	}

	.box-bottom {
		border-bottom: 2px solid var(--color-slate-600);
	}

	.box-right {
		border-right: 2px solid var(--color-slate-600);
	}

	.given {
		background: var(--color-slate-100);
	}

	.given:hover {
		background: var(--color-slate-100);
	}

	.given .cell-value {
		color: var(--color-slate-800);
		font-weight: 700;
	}

	.solved .cell-input,
	.solved .cell-value {
		color: var(--color-success-600);
		font-weight: 600;
	}

	.user-input .cell-input,
	.user-input .cell-value {
		color: var(--color-primary-600);
		font-weight: 600;
	}

	.cell-value {
		color: var(--color-slate-600);
		font-size: clamp(1.125rem, 4.5vw, 1.75rem);
		font-variant-numeric: tabular-nums;
		font-weight: 500;
		line-height: 1;
		user-select: none;
	}

	.cell-input {
		background: transparent;
		border: none;
		caret-color: var(--color-primary-500);
		color: var(--color-primary-600);
		font-size: clamp(1.125rem, 4.5vw, 1.75rem);
		font-variant-numeric: tabular-nums;
		font-weight: 600;
		height: 100%;
		line-height: 1;
		outline: none;
		text-align: center;
		transition: background var(--duration-fast) var(--ease-out);
		width: 100%;
	}

	.cell-input:focus {
		background: var(--color-primary-50);
	}

	.cell-input::placeholder {
		color: var(--color-slate-300);
	}

	.cell-input::selection {
		background: var(--color-primary-100);
	}
</style>
