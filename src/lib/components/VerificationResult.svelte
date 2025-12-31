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
			? 'The prover knows a valid solution'
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
		align-items: center;
		animation: scaleIn var(--duration-slow) var(--ease-spring);
		border-radius: var(--radius-lg);
		display: flex;
		flex: 1;
		flex-direction: column;
		justify-content: center;
		margin-top: var(--space-3);
		min-height: 0;
		overflow: hidden;
		padding: var(--space-4);
		text-align: center;
	}

	.verify-result.valid {
		background: linear-gradient(160deg, var(--color-success-50) 0%, var(--color-success-100) 100%);
		border: 1px solid var(--color-success-400);
		box-shadow: 0 4px 12px rgba(16, 185, 129, 0.15);
	}

	.verify-result.invalid {
		background: linear-gradient(160deg, var(--color-error-50) 0%, var(--color-error-100) 100%);
		border: 1px solid var(--color-error-400);
		box-shadow: 0 4px 12px rgba(239, 68, 68, 0.15);
	}

	.result-badge {
		animation: scaleIn var(--duration-slow) var(--ease-spring) 100ms backwards;
		margin-bottom: var(--space-2);
		position: relative;
	}

	.badge-icon {
		align-items: center;
		border-radius: var(--radius-full);
		display: flex;
		height: 44px;
		justify-content: center;
		position: relative;
		width: 44px;
		z-index: 1;
	}

	.verify-result.valid .badge-icon {
		background: var(--gradient-success);
		box-shadow: 0 4px 14px rgba(16, 185, 129, 0.4);
		color: white;
	}

	.verify-result.invalid .badge-icon {
		background: linear-gradient(135deg, var(--color-error-400) 0%, var(--color-error-600) 100%);
		box-shadow: 0 4px 14px rgba(239, 68, 68, 0.4);
		color: white;
	}

	.badge-icon svg {
		height: 22px;
		width: 22px;
	}

	.badge-ring {
		animation: pulse 2s ease-in-out infinite;
		border-radius: var(--radius-full);
		inset: -5px;
		opacity: 0.4;
		position: absolute;
	}

	.verify-result.valid .badge-ring {
		border: 2px solid var(--color-success-500);
	}

	.verify-result.invalid .badge-ring {
		border: 2px solid var(--color-error-500);
	}

	.result-title {
		animation: slideUp var(--duration-normal) var(--ease-out) 150ms backwards;
		font-size: 1rem;
		font-weight: 700;
		letter-spacing: -0.01em;
		margin: 0 0 var(--space-1);
	}

	.verify-result.valid .result-title {
		color: var(--color-success-700);
	}

	.verify-result.invalid .result-title {
		color: var(--color-error-700);
	}

	.result-desc {
		animation: slideUp var(--duration-normal) var(--ease-out) 200ms backwards;
		color: var(--color-slate-500);
		font-size: 0.75rem;
		line-height: 1.4;
		margin: 0 0 var(--space-3);
		max-width: 220px;
	}

	.result-meta {
		align-items: center;
		animation: slideUp var(--duration-normal) var(--ease-out) 250ms backwards;
		backdrop-filter: blur(8px);
		background: rgba(255, 255, 255, 0.7);
		border-radius: var(--radius-sm);
		display: flex;
		gap: var(--space-3);
		padding: var(--space-2) var(--space-3);
	}

	.meta-item {
		display: flex;
		flex-direction: column;
		gap: 2px;
	}

	.meta-label {
		color: var(--color-slate-400);
		font-size: 0.625rem;
		font-weight: 600;
		letter-spacing: 0.05em;
		text-transform: uppercase;
	}

	.meta-value {
		color: var(--color-slate-700);
		font-family: var(--font-mono);
		font-size: 0.75rem;
		font-weight: 600;
	}

	.meta-divider {
		background: var(--color-slate-200);
		height: 24px;
		width: 1px;
	}
</style>
