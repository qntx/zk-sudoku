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
		background: linear-gradient(145deg, #f8fafc, #f1f5f9);
		border-radius: 20px;
		box-shadow:
			0 4px 6px -1px rgba(0, 0, 0, 0.05),
			0 10px 15px -3px rgba(0, 0, 0, 0.08),
			0 20px 25px -5px rgba(0, 0, 0, 0.05);
		max-width: 540px;
		padding: 1rem;
		width: 100%;
	}

	.board {
		aspect-ratio: 1;
		background: #ffffff;
		border: 2px solid #334155;
		border-radius: 12px;
		display: grid;
		grid-template-columns: repeat(9, 1fr);
		overflow: hidden;
		width: 100%;
	}

	.cell {
		align-items: center;
		aspect-ratio: 1;
		background: #ffffff;
		border: 1px solid #e2e8f0;
		display: flex;
		justify-content: center;
		transition: all 0.15s ease;
	}

	.cell:hover {
		background: #f8fafc;
	}

	.box-bottom {
		border-bottom: 2px solid #475569;
	}

	.box-right {
		border-right: 2px solid #475569;
	}

	.given {
		background: #f1f5f9;
	}

	.given .cell-value {
		color: #1e293b;
		font-weight: 700;
	}

	.solved .cell-input,
	.solved .cell-value {
		color: #059669;
		font-weight: 600;
	}

	.user-input .cell-input,
	.user-input .cell-value {
		color: #4f46e5;
		font-weight: 500;
	}

	.cell-value {
		color: #475569;
		font-size: clamp(1.25rem, 5vw, 2rem);
		font-variant-numeric: tabular-nums;
		font-weight: 500;
		user-select: none;
	}

	.cell-input {
		background: transparent;
		border: none;
		caret-color: #4f46e5;
		color: #4f46e5;
		font-size: clamp(1.25rem, 5vw, 2rem);
		font-variant-numeric: tabular-nums;
		font-weight: 500;
		height: 100%;
		outline: none;
		text-align: center;
		width: 100%;
	}

	.cell-input:focus {
		background: #eef2ff;
	}

	.cell-input::placeholder {
		color: #cbd5e1;
	}
</style>
