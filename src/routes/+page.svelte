<script lang="ts">
	import confetti from 'canvas-confetti';

	import { downloadFile } from '$lib/download';
	import {
		cloneGrid,
		createEmptyGrid,
		generateSudoku,
		isGridEmpty,
		parseGrid,
		serializeGrid,
		validateSolution,
		type DifficultyLevel,
		type SudokuGrid
	} from '$lib/sudoku';
	import { generateProof, parseProof, serializeProof, verifyProof, type ZkProof } from '$lib/zk';

	import FileUpload from '$lib/components/FileUpload.svelte';
	import SudokuBoard from '$lib/components/SudokuBoard.svelte';
	import VerificationResult from '$lib/components/VerificationResult.svelte';

	type MessageType = 'error' | 'info' | 'success';
	type Mode = 'generate' | 'prove' | 'verify';
	type VerifyResult = 'invalid' | 'valid' | null;

	const CELEBRATION_DURATION_MS = 2000;

	let currentMode: Mode = $state('generate');
	let currentProof: ZkProof | null = $state(null);
	let displayGrid: SudokuGrid = $state(createEmptyGrid());
	let isLoading = $state(false);
	let isSolutionVisible = $state(false);
	let messageType: MessageType = $state('info');
	let puzzleGrid: SudokuGrid = $state(createEmptyGrid());
	let selectedDifficulty: DifficultyLevel = $state('medium');
	let solutionGrid: SudokuGrid | null = $state(null);
	let statusMessage = $state('');
	let verificationResult: VerifyResult = $state(null);

	const canVerify = $derived(!isLoading && currentProof !== null && !isGridEmpty(puzzleGrid));

	const extractErrorMessage = (error: unknown): string =>
		error instanceof Error ? error.message : 'Unknown error';

	const updateStatus = (text: string, type: MessageType = 'info'): void => {
		messageType = type;
		statusMessage = text;
	};

	const resetState = (): void => {
		currentProof = null;
		displayGrid = createEmptyGrid();
		isSolutionVisible = false;
		puzzleGrid = createEmptyGrid();
		solutionGrid = null;
		statusMessage = '';
		verificationResult = null;
	};

	const switchMode = (newMode: Mode): void => {
		currentMode = newMode;
		resetState();
	};

	const handleCellChange = (row: number, col: number, value: number): void => {
		displayGrid[row][col] = value;
		displayGrid = displayGrid;
	};

	const handleGeneratePuzzle = async (): Promise<void> => {
		isLoading = true;
		updateStatus('Generating...');
		try {
			const result = await generateSudoku(selectedDifficulty);
			displayGrid = cloneGrid(result.puzzle);
			isSolutionVisible = false;
			puzzleGrid = result.puzzle;
			solutionGrid = result.solution;
			updateStatus('Sudoku generated successfully', 'success');
		} catch (error) {
			updateStatus(`Generation failed: ${extractErrorMessage(error)}`, 'error');
		} finally {
			isLoading = false;
		}
	};

	const handlePuzzleUpload = (content: string): void => {
		const parsed = parseGrid(content);
		if (!parsed) {
			updateStatus('Invalid puzzle file', 'error');
			return;
		}
		displayGrid = cloneGrid(parsed);
		puzzleGrid = parsed;
		updateStatus('Puzzle loaded', 'success');
	};

	const handleSolutionUpload = (content: string): void => {
		const parsed = parseGrid(content);
		if (!parsed) {
			updateStatus('Invalid solution file', 'error');
			return;
		}
		displayGrid = cloneGrid(parsed);
		isSolutionVisible = true;
		solutionGrid = parsed;
		updateStatus('Solution loaded', 'success');
	};

	const handleProofUpload = (content: string): void => {
		const parsed = parseProof(content);
		if (!parsed) {
			updateStatus('Invalid proof file', 'error');
			return;
		}
		currentProof = parsed;
		updateStatus('Proof loaded', 'success');
	};

	const handleGenerateProof = async (): Promise<void> => {
		if (!solutionGrid) {
			updateStatus('Please upload a solution first', 'error');
			return;
		}

		isLoading = true;
		try {
			updateStatus('Validating solution...');
			const isValid = await validateSolution(puzzleGrid, solutionGrid);
			if (!isValid) {
				updateStatus('Invalid solution for this puzzle', 'error');
				return;
			}
			updateStatus('Generating proof...');
			currentProof = await generateProof(puzzleGrid, solutionGrid);
			updateStatus('Proof generated successfully', 'success');
		} catch (error) {
			updateStatus(`Failed to generate proof: ${extractErrorMessage(error)}`, 'error');
		} finally {
			isLoading = false;
		}
	};

	const handleVerifyProof = async (): Promise<void> => {
		if (!currentProof || isGridEmpty(puzzleGrid)) return;

		isLoading = true;
		verificationResult = null;
		updateStatus('Verifying proof...');
		try {
			const isValid = await verifyProof(currentProof, puzzleGrid);
			verificationResult = isValid ? 'valid' : 'invalid';
			if (isValid) triggerCelebration();
			statusMessage = '';
		} catch (error) {
			updateStatus(`Verification failed: ${extractErrorMessage(error)}`, 'error');
		} finally {
			isLoading = false;
		}
	};

	const toggleSolutionVisibility = (): void => {
		if (!solutionGrid) return;
		isSolutionVisible = !isSolutionVisible;
		displayGrid = isSolutionVisible ? cloneGrid(solutionGrid) : cloneGrid(puzzleGrid);
	};

	const downloadPuzzleFile = (): void => {
		downloadFile(serializeGrid(puzzleGrid), 'puzzle.json');
	};

	const downloadSolutionFile = (): void => {
		if (solutionGrid) downloadFile(serializeGrid(solutionGrid), 'solution.json');
	};

	const downloadProofFile = (): void => {
		if (currentProof) downloadFile(serializeProof(currentProof), 'proof.json');
	};

	const triggerCelebration = (): void => {
		const endTime = Date.now() + CELEBRATION_DURATION_MS;
		const animateConfetti = (): void => {
			confetti({ angle: 60, origin: { x: 0 }, particleCount: 3, spread: 55 });
			confetti({ angle: 120, origin: { x: 1 }, particleCount: 3, spread: 55 });
			if (Date.now() < endTime) requestAnimationFrame(animateConfetti);
		};
		animateConfetti();
	};
</script>

<svelte:head>
	<title>ZK Sudoku</title>
	<script src="https://cdn.jsdelivr.net/npm/snarkjs@0.7.5/build/snarkjs.min.js"></script>
</svelte:head>

<main class="container">
	<header>
		<h1>ZK Sudoku</h1>
		<p class="subtitle">Zero-Knowledge Proof for Sudoku Solutions</p>
	</header>

	<nav class="mode-tabs">
		<button class:active={currentMode === 'generate'} onclick={() => switchMode('generate')}
			>Generate</button
		>
		<button class:active={currentMode === 'prove'} onclick={() => switchMode('prove')}>Prove</button
		>
		<button class:active={currentMode === 'verify'} onclick={() => switchMode('verify')}
			>Verify</button
		>
	</nav>

	<section class="content">
		<div class="board-container">
			<SudokuBoard
				grid={displayGrid}
				puzzle={puzzleGrid}
				editable={currentMode === 'generate' && !isSolutionVisible}
				onCellChange={handleCellChange}
				showSolution={isSolutionVisible}
			/>
		</div>

		<aside class="controls">
			{#if currentMode === 'generate'}
				<div class="control-group">
					<h3>Generate Sudoku</h3>
					<div class="difficulty-selector">
						<label for="difficulty">Difficulty</label>
						<select id="difficulty" bind:value={selectedDifficulty}>
							<option value="easy">Easy</option>
							<option value="medium">Medium</option>
							<option value="hard">Hard</option>
							<option value="expert">Expert</option>
						</select>
					</div>
					<button class="primary-btn" onclick={handleGeneratePuzzle}>Generate New</button>
					{#if solutionGrid}
						<button class="secondary-btn" onclick={toggleSolutionVisibility}>
							{isSolutionVisible ? 'Show Puzzle' : 'Show Solution'}
						</button>
						<div class="download-group">
							<button class="download-btn" onclick={downloadPuzzleFile}>Download Puzzle</button>
							<button class="download-btn" onclick={downloadSolutionFile}>Download Solution</button>
						</div>
					{/if}
				</div>
			{:else if currentMode === 'prove'}
				<div class="control-group">
					<h3>Generate Proof</h3>
					<p class="hint">Upload puzzle and solution to generate a ZK proof</p>
					<div class="upload-group">
						<FileUpload label="Upload Puzzle" onFile={handlePuzzleUpload} />
						<FileUpload label="Upload Solution" onFile={handleSolutionUpload} />
					</div>
					<button class="primary-btn" onclick={handleGenerateProof} disabled={isLoading}>
						{isLoading ? 'Generating...' : 'Generate Proof'}
					</button>
					{#if currentProof}
						<div class="success-action">
							<button class="success-btn" onclick={downloadProofFile}>Download Proof</button>
						</div>
					{/if}
				</div>
			{:else if currentMode === 'verify'}
				<div class="control-group">
					<h3>Verify Proof</h3>
					<p class="hint">Upload the puzzle and proof to verify</p>
					<div class="upload-group">
						<FileUpload label="Upload Puzzle" onFile={handlePuzzleUpload} />
						<FileUpload label="Upload Proof" onFile={handleProofUpload} />
					</div>
					<button class="primary-btn" onclick={handleVerifyProof} disabled={!canVerify}>
						{isLoading ? 'Verifying...' : 'Verify Proof'}
					</button>
					{#if statusMessage}
						<div class="message {messageType}">{statusMessage}</div>
					{/if}
				</div>
				{#if verificationResult}
					<VerificationResult result={verificationResult} />
				{/if}
			{/if}

			{#if statusMessage && currentMode !== 'verify'}
				<div class="message {messageType}">{statusMessage}</div>
			{/if}
		</aside>
	</section>
</main>

<style>
	.container {
		animation: fadeIn var(--duration-slow) var(--ease-out);
		margin: 0 auto;
		max-width: 1000px;
		min-height: 100vh;
		padding: var(--space-10) var(--space-6);
	}

	header {
		margin-bottom: var(--space-10);
		text-align: center;
	}

	h1 {
		background: var(--gradient-hero);
		background-clip: text;
		font-size: clamp(2rem, 5vw, 2.75rem);
		font-weight: 800;
		letter-spacing: -0.03em;
		line-height: 1.1;
		margin: 0;
		-webkit-background-clip: text;
		-webkit-text-fill-color: transparent;
	}

	.subtitle {
		color: var(--color-slate-500);
		font-size: 1.125rem;
		font-weight: 500;
		margin: var(--space-3) 0 0;
	}

	.mode-tabs {
		animation: slideUp var(--duration-slow) var(--ease-out) 100ms backwards;
		background: white;
		border: 1px solid var(--color-slate-200);
		border-radius: var(--radius-xl);
		box-shadow: var(--shadow-sm);
		display: flex;
		gap: var(--space-2);
		justify-content: center;
		margin: 0 auto var(--space-10);
		padding: var(--space-2);
		width: fit-content;
	}

	.mode-tabs button {
		background: transparent;
		border: none;
		border-radius: var(--radius-lg);
		color: var(--color-slate-500);
		cursor: pointer;
		font-size: 0.9375rem;
		font-weight: 600;
		padding: var(--space-3) var(--space-6);
		position: relative;
		transition: all var(--duration-normal) var(--ease-out);
	}

	.mode-tabs button:hover:not(.active) {
		background: var(--color-slate-100);
		color: var(--color-slate-700);
	}

	.mode-tabs button.active {
		background: var(--gradient-primary);
		box-shadow: var(--shadow-primary);
		color: white;
	}

	.content {
		align-items: center;
		animation: slideUp var(--duration-slow) var(--ease-out) 200ms backwards;
		display: flex;
		flex-direction: column;
		gap: var(--space-10);
	}

	@media (min-width: 900px) {
		.content {
			align-items: stretch;
			flex-direction: row;
			gap: var(--space-12);
			justify-content: center;
		}

		.board-container {
			display: flex;
		}

		.controls {
			max-height: 572px;
		}
	}

	.board-container {
		flex: 0 0 auto;
		max-width: 540px;
		width: 100%;
	}

	.controls {
		display: flex;
		flex: 0 0 auto;
		flex-direction: column;
		gap: var(--space-3);
		max-width: 320px;
		width: 100%;
	}

	.control-group {
		animation: scaleIn var(--duration-slow) var(--ease-out);
		background: white;
		border: 1px solid var(--color-slate-200);
		border-radius: var(--radius-xl);
		box-shadow: var(--shadow-md);
		padding: var(--space-6);
	}

	.control-group h3 {
		color: var(--color-slate-800);
		font-size: 1.125rem;
		font-weight: 700;
		letter-spacing: -0.01em;
		margin: 0 0 var(--space-5);
	}

	.difficulty-selector {
		display: flex;
		flex-direction: column;
		gap: var(--space-2);
		margin-bottom: var(--space-5);
	}

	.difficulty-selector label {
		color: var(--color-slate-500);
		font-size: 0.75rem;
		font-weight: 600;
		letter-spacing: 0.05em;
		text-transform: uppercase;
	}

	.difficulty-selector select {
		appearance: none;
		background: var(--color-slate-50)
			url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='%2364748b' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpolyline points='6 9 12 15 18 9'%3E%3C/polyline%3E%3C/svg%3E")
			no-repeat right 12px center;
		border: 1px solid var(--color-slate-200);
		border-radius: var(--radius-md);
		color: var(--color-slate-800);
		cursor: pointer;
		font-size: 0.9375rem;
		font-weight: 500;
		padding: var(--space-3) var(--space-10) var(--space-3) var(--space-4);
		transition: all var(--duration-fast) var(--ease-out);
	}

	.difficulty-selector select:hover {
		border-color: var(--color-slate-300);
	}

	.difficulty-selector select:focus {
		border-color: var(--color-primary-500);
		box-shadow: 0 0 0 3px var(--color-primary-50);
		outline: none;
	}

	.primary-btn {
		background: var(--gradient-primary);
		border: none;
		border-radius: var(--radius-lg);
		color: white;
		cursor: pointer;
		font-size: 1rem;
		font-weight: 600;
		padding: var(--space-4) var(--space-5);
		transition: all var(--duration-normal) var(--ease-out);
		width: 100%;
	}

	.primary-btn:hover:not(:disabled) {
		box-shadow: var(--shadow-primary-lg);
		filter: brightness(1.05);
		transform: translateY(-2px);
	}

	.primary-btn:active:not(:disabled) {
		transform: translateY(0);
	}

	.primary-btn:disabled {
		cursor: not-allowed;
		opacity: 0.5;
	}

	.secondary-btn {
		background: var(--color-slate-100);
		border: 1px solid var(--color-slate-200);
		border-radius: var(--radius-md);
		color: var(--color-slate-600);
		cursor: pointer;
		font-size: 0.9375rem;
		font-weight: 600;
		margin-top: var(--space-3);
		padding: var(--space-3) var(--space-4);
		transition: all var(--duration-fast) var(--ease-out);
		width: 100%;
	}

	.secondary-btn:hover {
		background: var(--color-slate-200);
		border-color: var(--color-slate-300);
		color: var(--color-slate-700);
	}

	.download-group {
		border-top: 1px solid var(--color-slate-200);
		display: flex;
		flex-direction: column;
		gap: var(--space-2);
		margin-top: var(--space-5);
		padding-top: var(--space-5);
	}

	.download-btn {
		align-items: center;
		background: white;
		border: 1px solid var(--color-slate-200);
		border-radius: var(--radius-md);
		color: var(--color-slate-600);
		cursor: pointer;
		display: flex;
		font-size: 0.875rem;
		font-weight: 500;
		gap: var(--space-2);
		justify-content: center;
		padding: var(--space-3) var(--space-4);
		transition: all var(--duration-fast) var(--ease-out);
		width: 100%;
	}

	.download-btn:hover {
		background: var(--color-slate-50);
		border-color: var(--color-primary-400);
		color: var(--color-primary-600);
	}

	.upload-group {
		display: flex;
		flex-direction: column;
		gap: var(--space-3);
		margin-bottom: var(--space-5);
	}

	.hint {
		color: var(--color-slate-500);
		font-size: 0.875rem;
		line-height: 1.5;
		margin: 0 0 var(--space-4);
	}

	.success-action {
		animation: slideUp var(--duration-normal) var(--ease-spring);
		border-top: 1px solid var(--color-slate-200);
		margin-top: var(--space-5);
		padding-top: var(--space-5);
	}

	.success-btn {
		background: var(--gradient-success);
		border: none;
		border-radius: var(--radius-lg);
		color: white;
		cursor: pointer;
		font-size: 1rem;
		font-weight: 600;
		padding: var(--space-4) var(--space-5);
		transition: all var(--duration-normal) var(--ease-out);
		width: 100%;
	}

	.success-btn:hover {
		box-shadow: var(--shadow-success);
		transform: translateY(-2px);
	}

	.success-btn:active {
		transform: translateY(0);
	}

	.message {
		animation: slideUp var(--duration-normal) var(--ease-spring);
		border-radius: var(--radius-lg);
		font-size: 0.875rem;
		font-weight: 600;
		margin-top: var(--space-5);
		padding: var(--space-4) var(--space-5);
		text-align: center;
	}

	.message.error {
		background: var(--color-error-50);
		border: 1px solid var(--color-error-100);
		color: var(--color-error-600);
	}

	.message.info {
		background: var(--color-primary-50);
		border: 1px solid var(--color-primary-100);
		color: var(--color-primary-600);
	}

	.message.success {
		background: var(--color-success-50);
		border: 1px solid var(--color-success-100);
		color: var(--color-success-600);
	}
</style>
