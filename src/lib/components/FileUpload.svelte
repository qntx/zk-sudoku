<script lang="ts">
	interface Props {
		accept?: string;
		label: string;
		onFile: (content: string) => void;
	}

	const { accept = '.json', label, onFile }: Props = $props();

	let fileInput = $state<HTMLInputElement | null>(null);

	const handleChange = async (e: Event & { currentTarget: HTMLInputElement }): Promise<void> => {
		const file = e.currentTarget.files?.[0];
		if (!file) return;
		onFile(await file.text());
		e.currentTarget.value = '';
	};
</script>

<button type="button" class="upload-btn" onclick={() => fileInput?.click()}>
	<svg
		viewBox="0 0 24 24"
		fill="none"
		stroke="currentColor"
		stroke-width="2"
		stroke-linecap="round"
		stroke-linejoin="round"
	>
		<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
		<polyline points="17 8 12 3 7 8" />
		<line x1="12" y1="3" x2="12" y2="15" />
	</svg>
	{label}
</button>

<input type="file" bind:this={fileInput} {accept} onchange={handleChange} hidden />

<style>
	.upload-btn {
		align-items: center;
		background: var(--color-slate-50);
		border: 2px dashed var(--color-slate-300);
		border-radius: var(--radius-md);
		color: var(--color-slate-500);
		cursor: pointer;
		display: inline-flex;
		font-size: 0.875rem;
		font-weight: 600;
		gap: var(--space-2);
		justify-content: center;
		padding: var(--space-3) var(--space-4);
		transition: all var(--duration-normal) var(--ease-out);
		width: 100%;
	}

	.upload-btn:hover {
		background: var(--color-primary-50);
		border-color: var(--color-primary-400);
		border-style: solid;
		color: var(--color-primary-600);
	}

	.upload-btn:focus-visible {
		border-color: var(--color-primary-500);
		box-shadow: 0 0 0 3px var(--color-primary-50);
		outline: none;
	}

	.upload-btn:active {
		transform: scale(0.98);
	}

	.upload-btn svg {
		height: 18px;
		opacity: 0.6;
		transition: all var(--duration-fast) var(--ease-out);
		width: 18px;
	}

	.upload-btn:hover svg {
		opacity: 1;
		transform: translateY(-1px);
	}
</style>
