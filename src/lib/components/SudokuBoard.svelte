<script lang="ts">
	import type { Grid } from '$lib/sudoku';

	interface Props {
		grid: Grid;
		puzzle?: Grid;
		editable?: boolean;
		showSolution?: boolean;
		onCellChange?: (row: number, col: number, value: number) => void;
	}

	let { grid, puzzle, editable = false, showSolution = false, onCellChange }: Props = $props();

	const isGiven = (row: number, col: number) => puzzle?.[row][col] !== 0;

	const getCellClass = (row: number, col: number) => {
		const cell = grid[row][col];
		return [
			'cell',
			row % 3 === 2 && row !== 8 && 'box-bottom',
			col % 3 === 2 && col !== 8 && 'box-right',
			isGiven(row, col) ? 'given' : cell !== 0 && (showSolution ? 'solved' : 'user-input')
		]
			.filter(Boolean)
			.join(' ');
	};

	function handleInput(row: number, col: number, e: Event & { currentTarget: HTMLInputElement }) {
		const { value } = e.currentTarget;
		if (!value) {
			onCellChange?.(row, col, 0);
			return;
		}

		const num = parseInt(value.slice(-1), 10);
		if (num >= 1 && num <= 9) {
			onCellChange?.(row, col, num);
			e.currentTarget.value = String(num);
		} else {
			const cell = grid[row][col];
			e.currentTarget.value = cell ? String(cell) : '';
		}
	}
</script>

<div class="board-wrapper">
	<div class="board">
		{#each grid as row, rowIndex}
			{#each row as cell, colIndex}
				<div class={getCellClass(rowIndex, colIndex)}>
					{#if editable && !isGiven(rowIndex, colIndex)}
						<input
							type="text"
							inputmode="numeric"
							value={cell || ''}
							oninput={(e) => handleInput(rowIndex, colIndex, e)}
							class="cell-input"
						/>
					{:else}
						<span class="cell-value">{cell || ''}</span>
					{/if}
				</div>
			{/each}
		{/each}
	</div>
</div>

<style>
	.board-wrapper {
		width: 100%;
		max-width: 540px;
		padding: 1rem;
		background: linear-gradient(145deg, #f8fafc, #f1f5f9);
		border-radius: 20px;
		box-shadow:
			0 4px 6px -1px rgba(0, 0, 0, 0.05),
			0 10px 15px -3px rgba(0, 0, 0, 0.08),
			0 20px 25px -5px rgba(0, 0, 0, 0.05);
	}

	.board {
		display: grid;
		grid-template-columns: repeat(9, 1fr);
		width: 100%;
		aspect-ratio: 1;
		background: #ffffff;
		border: 2px solid #334155;
		border-radius: 12px;
		overflow: hidden;
	}

	.cell {
		display: flex;
		align-items: center;
		justify-content: center;
		border: 1px solid #e2e8f0;
		background: #ffffff;
		transition: all 0.15s ease;
		aspect-ratio: 1;
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

	.solved .cell-value,
	.solved .cell-input {
		color: #059669;
		font-weight: 600;
	}

	.user-input .cell-value,
	.user-input .cell-input {
		color: #4f46e5;
		font-weight: 500;
	}

	.cell-value {
		font-size: clamp(1.25rem, 5vw, 2rem);
		font-weight: 500;
		color: #475569;
		font-variant-numeric: tabular-nums;
		user-select: none;
	}

	.cell-input {
		width: 100%;
		height: 100%;
		border: none;
		background: transparent;
		text-align: center;
		font-size: clamp(1.25rem, 5vw, 2rem);
		font-weight: 500;
		color: #4f46e5;
		font-variant-numeric: tabular-nums;
		caret-color: #4f46e5;
		outline: none;
	}

	.cell-input:focus {
		background: #eef2ff;
	}

	.cell-input::placeholder {
		color: #cbd5e1;
	}
</style>
