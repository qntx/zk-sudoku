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
	import {
		generateProof,
		parseProof,
		serializeProof,
		verifyProof,
		type ZkProof
	} from '$lib/zk';

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
		<button class:active={currentMode === 'generate'} onclick={() => switchMode('generate')}>Generate</button>
		<button class:active={currentMode === 'prove'} onclick={() => switchMode('prove')}>Prove</button>
		<button class:active={currentMode === 'verify'} onclick={() => switchMode('verify')}>Verify</button>
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
		margin: 0 auto;
		max-width: 1000px;
		min-height: 100vh;
		padding: 2.5rem 1.5rem;
	}

	header {
		margin-bottom: 2.5rem;
		text-align: center;
	}

	h1 {
		background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
		background-clip: text;
		font-size: 2.75rem;
		font-weight: 800;
		letter-spacing: -0.02em;
		margin: 0;
		-webkit-background-clip: text;
		-webkit-text-fill-color: transparent;
	}

	.subtitle {
		color: #64748b;
		font-size: 1.125rem;
		margin: 0.75rem 0 0;
	}

	.mode-tabs {
		background: #ffffff;
		border-radius: 16px;
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
		display: flex;
		gap: 0.5rem;
		justify-content: center;
		margin: 0 auto 2.5rem;
		padding: 0.5rem;
		width: fit-content;
	}

	.mode-tabs button {
		background: transparent;
		border: none;
		border-radius: 12px;
		color: #64748b;
		cursor: pointer;
		font-size: 0.9375rem;
		font-weight: 600;
		padding: 0.875rem 1.75rem;
		transition: all 0.2s ease;
	}

	.mode-tabs button:hover {
		background: #f1f5f9;
		color: #475569;
	}

	.mode-tabs button.active {
		background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%);
		box-shadow: 0 4px 12px rgba(79, 70, 229, 0.3);
		color: #ffffff;
	}

	.content {
		align-items: center;
		display: flex;
		flex-direction: column;
		gap: 2.5rem;
	}

	@media (min-width: 900px) {
		.content {
			align-items: stretch;
			flex-direction: row;
			gap: 3rem;
			justify-content: center;
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
		max-width: 320px;
		width: 100%;
	}

	.control-group {
		background: #ffffff;
		border: 1px solid #e2e8f0;
		border-radius: 16px;
		box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
		padding: 1.75rem;
	}

	.control-group h3 {
		color: #1e293b;
		font-size: 1.125rem;
		font-weight: 700;
		margin: 0 0 1.25rem;
	}

	.difficulty-selector {
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
		margin-bottom: 1.25rem;
	}

	.difficulty-selector label {
		color: #64748b;
		font-size: 0.8125rem;
		font-weight: 600;
		letter-spacing: 0.05em;
		text-transform: uppercase;
	}

	.difficulty-selector select {
		background: #f8fafc;
		border: 1px solid #e2e8f0;
		border-radius: 10px;
		color: #1e293b;
		cursor: pointer;
		font-size: 0.9375rem;
		font-weight: 500;
		outline: none;
		padding: 0.75rem 1rem;
		transition: all 0.15s ease;
	}

	.difficulty-selector select:hover {
		border-color: #cbd5e1;
	}

	.difficulty-selector select:focus {
		border-color: #4f46e5;
		box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
	}

	.primary-btn {
		background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%);
		border: none;
		border-radius: 12px;
		color: #ffffff;
		cursor: pointer;
		font-size: 1rem;
		font-weight: 600;
		padding: 1rem 1.25rem;
		transition: all 0.2s ease;
		width: 100%;
	}

	.primary-btn:hover:not(:disabled) {
		box-shadow: 0 8px 20px rgba(79, 70, 229, 0.35);
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
		background: #f1f5f9;
		border: 1px solid #e2e8f0;
		border-radius: 10px;
		color: #475569;
		cursor: pointer;
		font-size: 0.9375rem;
		font-weight: 600;
		margin-top: 0.875rem;
		padding: 0.875rem 1rem;
		transition: all 0.15s ease;
		width: 100%;
	}

	.secondary-btn:hover {
		background: #e2e8f0;
		border-color: #cbd5e1;
	}

	.download-group {
		border-top: 1px solid #e2e8f0;
		display: flex;
		flex-direction: column;
		gap: 0.625rem;
		margin-top: 1.25rem;
		padding-top: 1.25rem;
	}

	.download-btn {
		align-items: center;
		background: #ffffff;
		border: 1px solid #e2e8f0;
		border-radius: 10px;
		color: #475569;
		cursor: pointer;
		display: flex;
		font-size: 0.875rem;
		font-weight: 500;
		gap: 0.5rem;
		justify-content: center;
		padding: 0.75rem 1rem;
		transition: all 0.15s ease;
		width: 100%;
	}

	.download-btn:hover {
		background: #f8fafc;
		border-color: #cbd5e1;
		color: #1e293b;
	}

	.upload-group {
		display: flex;
		flex-direction: column;
		gap: 0.875rem;
		margin-bottom: 1.25rem;
	}

	.hint {
		color: #64748b;
		font-size: 0.875rem;
		line-height: 1.4;
		margin: 0 0 1rem;
	}

	.success-action {
		border-top: 1px solid #e2e8f0;
		margin-top: 1.25rem;
		padding-top: 1.25rem;
	}

	.success-btn {
		background: linear-gradient(135deg, #059669 0%, #10b981 100%);
		border: none;
		border-radius: 12px;
		color: #ffffff;
		cursor: pointer;
		font-size: 1rem;
		font-weight: 600;
		padding: 1rem 1.25rem;
		transition: all 0.2s ease;
		width: 100%;
	}

	.success-btn:hover {
		box-shadow: 0 8px 20px rgba(5, 150, 105, 0.35);
		transform: translateY(-2px);
	}

	.message {
		border-radius: 12px;
		font-size: 0.9375rem;
		font-weight: 600;
		margin-top: 1.25rem;
		padding: 1rem 1.25rem;
		text-align: center;
	}

	.message.error {
		background: #fef2f2;
		border: 1px solid #fecaca;
		color: #dc2626;
	}

	.message.info {
		background: #eff6ff;
		border: 1px solid #bfdbfe;
		color: #2563eb;
	}

	.message.success {
		background: #ecfdf5;
		border: 1px solid #a7f3d0;
		color: #059669;
	}
</style>
