<script lang="ts">
	interface Props {
		label: string;
		accept?: string;
		onFile: (content: string) => void;
	}

	let { label, accept = '.json', onFile }: Props = $props();

	let fileInput = $state<HTMLInputElement | null>(null);

	async function handleChange(e: Event & { currentTarget: HTMLInputElement }) {
		const file = e.currentTarget.files?.[0];
		if (!file) return;

		onFile(await file.text());
		e.currentTarget.value = '';
	}
</script>

<button type="button" class="upload-btn" onclick={() => fileInput?.click()}>
	<svg
		xmlns="http://www.w3.org/2000/svg"
		width="18"
		height="18"
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
		display: inline-flex;
		align-items: center;
		justify-content: center;
		gap: 0.5rem;
		width: 100%;
		padding: 0.875rem 1rem;
		background: #f8fafc;
		border: 2px dashed #cbd5e1;
		border-radius: 10px;
		color: #64748b;
		font-size: 0.875rem;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.15s ease;
	}

	.upload-btn:hover {
		background: #f1f5f9;
		border-color: #4f46e5;
		color: #4f46e5;
	}

	.upload-btn svg {
		opacity: 0.7;
	}

	.upload-btn:hover svg {
		opacity: 1;
	}
</style>
