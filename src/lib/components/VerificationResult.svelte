<script lang="ts">
	type Result = 'valid' | 'invalid';

	interface Props {
		result: Result;
	}

	const { result }: Props = $props();

	const isValid = $derived(result === 'valid');

	const config = $derived({
		title: isValid ? 'Proof Verified' : 'Verification Failed',
		description: isValid
			? 'The prover knows a valid solution without revealing it'
			: 'The proof does not match this puzzle'
	});
</script>

<div class="verify-result" class:valid={isValid} class:invalid={!isValid}>
	<div class="result-badge">
		<div class="badge-icon">
			{#if isValid}
				<svg
					xmlns="http://www.w3.org/2000/svg"
					viewBox="0 0 24 24"
					fill="none"
					stroke="currentColor"
					stroke-width="2.5"
					stroke-linecap="round"
					stroke-linejoin="round"
				>
					<polyline points="20 6 9 17 4 12"></polyline>
				</svg>
			{:else}
				<svg
					xmlns="http://www.w3.org/2000/svg"
					viewBox="0 0 24 24"
					fill="none"
					stroke="currentColor"
					stroke-width="2.5"
					stroke-linecap="round"
					stroke-linejoin="round"
				>
					<line x1="18" y1="6" x2="6" y2="18"></line>
					<line x1="6" y1="6" x2="18" y2="18"></line>
				</svg>
			{/if}
		</div>
		<div class="badge-ring"></div>
	</div>
	<h3 class="result-title">{config.title}</h3>
	<p class="result-desc">{config.description}</p>
	<div class="result-meta">
		<div class="meta-item">
			<span class="meta-label">Protocol</span>
			<span class="meta-value">Groth16</span>
		</div>
		<div class="meta-divider"></div>
		<div class="meta-item">
			<span class="meta-label">Curve</span>
			<span class="meta-value">BN128</span>
		</div>
	</div>
</div>

<style>
	.verify-result {
		margin-top: 1rem;
		padding: 1.25rem;
		border-radius: 16px;
		flex: 1;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		text-align: center;
		min-height: 0;
		overflow: hidden;
	}

	.verify-result.valid {
		background: linear-gradient(160deg, #ecfdf5 0%, #d1fae5 50%, #a7f3d0 100%);
		border: 1px solid #6ee7b7;
		box-shadow:
			0 4px 6px -1px rgba(16, 185, 129, 0.1),
			0 2px 4px -1px rgba(16, 185, 129, 0.06);
	}

	.verify-result.invalid {
		background: linear-gradient(160deg, #fef2f2 0%, #fee2e2 50%, #fecaca 100%);
		border: 1px solid #fca5a5;
		box-shadow:
			0 4px 6px -1px rgba(239, 68, 68, 0.1),
			0 2px 4px -1px rgba(239, 68, 68, 0.06);
	}

	.result-badge {
		position: relative;
		margin-bottom: 0.75rem;
	}

	.badge-icon {
		width: 48px;
		height: 48px;
		border-radius: 50%;
		display: flex;
		align-items: center;
		justify-content: center;
		position: relative;
		z-index: 1;
	}

	.verify-result.valid .badge-icon {
		background: linear-gradient(135deg, #10b981 0%, #059669 100%);
		color: #ffffff;
		box-shadow: 0 4px 12px rgba(16, 185, 129, 0.4);
	}

	.verify-result.invalid .badge-icon {
		background: linear-gradient(135deg, #f87171 0%, #dc2626 100%);
		color: #ffffff;
		box-shadow: 0 4px 12px rgba(239, 68, 68, 0.4);
	}

	.badge-icon svg {
		width: 24px;
		height: 24px;
	}

	.badge-ring {
		position: absolute;
		inset: -4px;
		border-radius: 50%;
		opacity: 0.3;
	}

	.verify-result.valid .badge-ring {
		border: 2px solid #10b981;
	}

	.verify-result.invalid .badge-ring {
		border: 2px solid #ef4444;
	}

	.result-title {
		margin: 0 0 0.25rem;
		font-size: 1rem;
		font-weight: 700;
		letter-spacing: -0.01em;
	}

	.verify-result.valid .result-title {
		color: #047857;
	}

	.verify-result.invalid .result-title {
		color: #b91c1c;
	}

	.result-desc {
		margin: 0 0 0.75rem;
		font-size: 0.75rem;
		line-height: 1.4;
		color: #64748b;
		max-width: 220px;
	}

	.result-meta {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		padding: 0.5rem 0.75rem;
		background: rgba(255, 255, 255, 0.6);
		border-radius: 8px;
		backdrop-filter: blur(4px);
	}

	.meta-item {
		display: flex;
		flex-direction: column;
		gap: 0.125rem;
	}

	.meta-label {
		font-size: 0.625rem;
		font-weight: 600;
		text-transform: uppercase;
		letter-spacing: 0.05em;
		color: #94a3b8;
	}

	.meta-value {
		font-size: 0.8125rem;
		font-weight: 600;
		color: #334155;
	}

	.meta-divider {
		width: 1px;
		height: 24px;
		background: rgba(0, 0, 0, 0.1);
	}
</style>
