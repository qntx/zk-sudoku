<script lang="ts">
	import SudokuBoard from '$lib/components/SudokuBoard.svelte';
	import FileUpload from '$lib/components/FileUpload.svelte';
	import {
		createEmptyGrid,
		generateSudoku,
		cloneGrid,
		gridToJson,
		jsonToGrid,
		validateSolution,
		isEmptyGrid,
		type Grid,
		type Difficulty
	} from '$lib/sudoku';
	import { generateProof, verifyProof, proofToJson, jsonToProof, type Proof } from '$lib/zk';
	import { downloadFile } from '$lib/download';

	type Mode = 'generate' | 'prove' | 'verify';

	let mode: Mode = $state('generate');
	let grid: Grid = $state(createEmptyGrid());
	let puzzle: Grid = $state(createEmptyGrid());
	let solution: Grid | null = $state(null);
	let showSolution = $state(false);
	let proof: Proof | null = $state(null);

	let loading = $state(false);
	let message = $state('');
	let messageType: 'success' | 'error' | 'info' = $state('info');
	let difficulty: Difficulty = $state('medium');

	const getErrorMessage = (err: unknown): string =>
		err instanceof Error ? err.message : 'Unknown error';

	const setMessage = (text: string, type: 'success' | 'error' | 'info' = 'info') => {
		message = text;
		messageType = type;
	};

	function setMode(newMode: Mode) {
		mode = newMode;
		grid = createEmptyGrid();
		puzzle = createEmptyGrid();
		solution = null;
		showSolution = false;
		proof = null;
		message = '';
	}

	async function handleGenerate() {
		loading = true;
		setMessage('Generating...');
		try {
			const result = await generateSudoku(difficulty);
			puzzle = result.puzzle;
			solution = result.solution;
			grid = cloneGrid(puzzle);
			showSolution = false;
			setMessage('Sudoku generated successfully', 'success');
		} catch (err) {
			setMessage(`Generation failed: ${getErrorMessage(err)}`, 'error');
		} finally {
			loading = false;
		}
	}

	function handleCellChange(row: number, col: number, value: number) {
		grid[row][col] = value;
	}

	function toggleSolution() {
		if (!solution) return;
		showSolution = !showSolution;
		grid = showSolution ? cloneGrid(solution) : cloneGrid(puzzle);
	}

	function downloadPuzzle() {
		downloadFile(gridToJson(puzzle), 'puzzle.json');
	}

	function downloadSolutionFile() {
		if (!solution) return;
		downloadFile(gridToJson(solution), 'solution.json');
	}

	function handlePuzzleUpload(content: string) {
		const parsed = jsonToGrid(content);
		if (!parsed) return setMessage('Invalid puzzle file', 'error');
		puzzle = parsed;
		grid = cloneGrid(parsed);
		setMessage('Puzzle loaded', 'success');
	}

	function handleSolutionUpload(content: string) {
		const parsed = jsonToGrid(content);
		if (!parsed) return setMessage('Invalid solution file', 'error');
		solution = parsed;
		grid = cloneGrid(parsed);
		showSolution = true;
		setMessage('Solution loaded', 'success');
	}

	function handleProofUpload(content: string) {
		const parsed = jsonToProof(content);
		if (!parsed) return setMessage('Invalid proof file', 'error');
		proof = parsed;
		setMessage('Proof loaded', 'success');
	}

	async function handleGenerateProof() {
		if (!solution) return setMessage('Please upload a solution first', 'error');

		loading = true;
		try {
			setMessage('Validating solution...');
			const valid = await validateSolution(puzzle, solution);
			if (!valid) {
				setMessage('Invalid solution for this puzzle', 'error');
				return;
			}

			setMessage('Generating proof...');
			proof = await generateProof(puzzle, solution);
			setMessage('Proof generated successfully', 'success');
		} catch (err) {
			setMessage(`Failed to generate proof: ${getErrorMessage(err)}`, 'error');
		} finally {
			loading = false;
		}
	}

	function downloadProof() {
		if (proof) downloadFile(proofToJson(proof), 'proof.json');
	}

	async function handleVerify() {
		if (!proof) return setMessage('Please upload a proof first', 'error');
		if (isEmptyGrid(puzzle)) return setMessage('Please upload a puzzle first', 'error');

		loading = true;
		setMessage('Verifying proof...');
		try {
			const valid = await verifyProof(proof, puzzle);
			setMessage(
				valid ? 'Proof is VALID - The prover knows a valid solution!' : 'Proof is INVALID',
				valid ? 'success' : 'error'
			);
		} catch (err) {
			setMessage(`Verification failed: ${getErrorMessage(err)}`, 'error');
		} finally {
			loading = false;
		}
	}
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
		<button class:active={mode === 'generate'} onclick={() => setMode('generate')}>
			Generate
		</button>
		<button class:active={mode === 'prove'} onclick={() => setMode('prove')}>Prove</button>
		<button class:active={mode === 'verify'} onclick={() => setMode('verify')}>Verify</button>
	</nav>

	<section class="content">
		<div class="board-container">
			<SudokuBoard
				{grid}
				{puzzle}
				editable={mode === 'generate' && !showSolution}
				{showSolution}
				onCellChange={handleCellChange}
			/>
		</div>

		<aside class="controls">
			{#if mode === 'generate'}
				<div class="control-group">
					<h3>Generate Sudoku</h3>
					<div class="difficulty-selector">
						<label for="difficulty">Difficulty</label>
						<select id="difficulty" bind:value={difficulty}>
							<option value="easy">Easy</option>
							<option value="medium">Medium</option>
							<option value="hard">Hard</option>
							<option value="expert">Expert</option>
						</select>
					</div>
					<button class="primary-btn" onclick={handleGenerate}>Generate New</button>

					{#if solution}
						<button class="secondary-btn" onclick={toggleSolution}>
							{showSolution ? 'Show Puzzle' : 'Show Solution'}
						</button>

						<div class="download-group">
							<button class="download-btn" onclick={downloadPuzzle}>Download Puzzle</button>
							<button class="download-btn" onclick={downloadSolutionFile}>Download Solution</button>
						</div>
					{/if}
				</div>
			{:else if mode === 'prove'}
				<div class="control-group">
					<h3>Generate Proof</h3>
					<p class="hint">Upload puzzle and solution to generate a ZK proof</p>
					<div class="upload-group">
						<FileUpload label="Upload Puzzle" onFile={handlePuzzleUpload} />
						<FileUpload label="Upload Solution" onFile={handleSolutionUpload} />
					</div>

					<button class="primary-btn" onclick={handleGenerateProof} disabled={loading}>
						{loading ? 'Generating...' : 'Generate Proof'}
					</button>

					{#if proof}
						<div class="success-action">
							<button class="success-btn" onclick={downloadProof}>Download Proof</button>
						</div>
					{/if}
				</div>
			{:else if mode === 'verify'}
				<div class="control-group">
					<h3>Verify Proof</h3>
					<p class="hint">Upload the puzzle and proof to verify</p>
					<div class="upload-group">
						<FileUpload label="Upload Puzzle" onFile={handlePuzzleUpload} />
						<FileUpload label="Upload Proof" onFile={handleProofUpload} />
					</div>

					<button
						class="primary-btn"
						onclick={handleVerify}
						disabled={loading || !proof || isEmptyGrid(puzzle)}
					>
						{loading ? 'Verifying...' : 'Verify Proof'}
					</button>
				</div>
			{/if}

			{#if message}
				<div class="message {messageType}">{message}</div>
			{/if}
		</aside>
	</section>
</main>

<style>
	:global(body) {
		margin: 0;
		background: linear-gradient(180deg, #f8fafc 0%, #e2e8f0 100%);
		color: #1e293b;
		font-family:
			'Inter',
			-apple-system,
			BlinkMacSystemFont,
			'Segoe UI',
			Roboto,
			sans-serif;
		min-height: 100vh;
	}

	.container {
		min-height: 100vh;
		max-width: 1000px;
		margin: 0 auto;
		padding: 2.5rem 1.5rem;
	}

	header {
		text-align: center;
		margin-bottom: 2.5rem;
	}

	h1 {
		font-size: 2.75rem;
		font-weight: 800;
		margin: 0;
		background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
		-webkit-background-clip: text;
		-webkit-text-fill-color: transparent;
		background-clip: text;
		letter-spacing: -0.02em;
	}

	.subtitle {
		color: #64748b;
		margin: 0.75rem 0 0;
		font-size: 1.125rem;
	}

	.mode-tabs {
		display: flex;
		justify-content: center;
		gap: 0.5rem;
		margin-bottom: 2.5rem;
		background: #ffffff;
		padding: 0.5rem;
		border-radius: 16px;
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
		width: fit-content;
		margin-left: auto;
		margin-right: auto;
	}

	.mode-tabs button {
		padding: 0.875rem 1.75rem;
		background: transparent;
		border: none;
		border-radius: 12px;
		color: #64748b;
		font-size: 0.9375rem;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s ease;
	}

	.mode-tabs button:hover {
		background: #f1f5f9;
		color: #475569;
	}

	.mode-tabs button.active {
		background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%);
		color: #ffffff;
		box-shadow: 0 4px 12px rgba(79, 70, 229, 0.3);
	}

	.content {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 2.5rem;
	}

	@media (min-width: 900px) {
		.content {
			flex-direction: row;
			align-items: flex-start;
			justify-content: center;
			gap: 3rem;
		}
	}

	.board-container {
		flex: 0 0 auto;
		width: 100%;
		max-width: 540px;
	}

	.controls {
		flex: 0 0 auto;
		width: 100%;
		max-width: 320px;
	}

	.control-group {
		background: #ffffff;
		border: 1px solid #e2e8f0;
		border-radius: 16px;
		padding: 1.75rem;
		box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
	}

	.control-group h3 {
		margin: 0 0 1.25rem;
		font-size: 1.125rem;
		font-weight: 700;
		color: #1e293b;
	}

	.primary-btn {
		width: 100%;
		padding: 1rem 1.25rem;
		background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%);
		border: none;
		border-radius: 12px;
		color: #ffffff;
		font-size: 1rem;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s ease;
	}

	.primary-btn:hover:not(:disabled) {
		transform: translateY(-2px);
		box-shadow: 0 8px 20px rgba(79, 70, 229, 0.35);
	}

	.primary-btn:active:not(:disabled) {
		transform: translateY(0);
	}

	.primary-btn:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}

	.secondary-btn {
		width: 100%;
		margin-top: 0.875rem;
		padding: 0.875rem 1rem;
		background: #f1f5f9;
		border: 1px solid #e2e8f0;
		border-radius: 10px;
		color: #475569;
		font-size: 0.9375rem;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.15s ease;
	}

	.secondary-btn:hover {
		background: #e2e8f0;
		border-color: #cbd5e1;
	}

	.download-group {
		display: flex;
		flex-direction: column;
		gap: 0.625rem;
		margin-top: 1.25rem;
		padding-top: 1.25rem;
		border-top: 1px solid #e2e8f0;
	}

	.download-btn {
		width: 100%;
		padding: 0.75rem 1rem;
		background: #ffffff;
		border: 1px solid #e2e8f0;
		border-radius: 10px;
		color: #475569;
		font-size: 0.875rem;
		font-weight: 500;
		cursor: pointer;
		transition: all 0.15s ease;
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 0.5rem;
	}

	.download-btn:hover {
		background: #f8fafc;
		border-color: #cbd5e1;
		color: #1e293b;
	}

	.difficulty-selector {
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
		margin-bottom: 1.25rem;
	}

	.difficulty-selector label {
		font-size: 0.8125rem;
		font-weight: 600;
		color: #64748b;
		text-transform: uppercase;
		letter-spacing: 0.05em;
	}

	.difficulty-selector select {
		padding: 0.75rem 1rem;
		background: #f8fafc;
		border: 1px solid #e2e8f0;
		border-radius: 10px;
		color: #1e293b;
		font-size: 0.9375rem;
		font-weight: 500;
		cursor: pointer;
		outline: none;
		transition: all 0.15s ease;
	}

	.difficulty-selector select:hover {
		border-color: #cbd5e1;
	}

	.difficulty-selector select:focus {
		border-color: #4f46e5;
		box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
	}

	.upload-group {
		display: flex;
		flex-direction: column;
		gap: 0.875rem;
		margin-bottom: 1.25rem;
	}

	.hint {
		margin: 0 0 1rem;
		font-size: 0.875rem;
		color: #64748b;
		line-height: 1.4;
	}

	.success-action {
		margin-top: 1.25rem;
		padding-top: 1.25rem;
		border-top: 1px solid #e2e8f0;
	}

	.success-btn {
		width: 100%;
		padding: 1rem 1.25rem;
		background: linear-gradient(135deg, #059669 0%, #10b981 100%);
		border: none;
		border-radius: 12px;
		color: #ffffff;
		font-size: 1rem;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s ease;
	}

	.success-btn:hover {
		transform: translateY(-2px);
		box-shadow: 0 8px 20px rgba(5, 150, 105, 0.35);
	}

	.message {
		margin-top: 1.25rem;
		padding: 1rem 1.25rem;
		border-radius: 12px;
		font-size: 0.9375rem;
		font-weight: 600;
		text-align: center;
	}

	.message.success {
		background: #ecfdf5;
		border: 1px solid #a7f3d0;
		color: #059669;
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
</style>
