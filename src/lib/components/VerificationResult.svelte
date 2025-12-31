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
	<div class="result-icon">
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
	<h3 class="result-title">{config.title}</h3>
	<p class="result-desc">{config.description}</p>
	<div class="result-meta">
		<span class="meta-tag">Groth16</span>
		<span class="meta-tag">BN128</span>
	</div>
</div>

<style>
	.verify-result {
		align-items: center;
		animation: scaleIn var(--duration-slow) var(--ease-spring);
		border-radius: var(--radius-xl);
		display: flex;
		flex: 1;
		flex-direction: column;
		justify-content: center;
		margin-top: var(--space-3);
		min-height: 0;
		padding: var(--space-5);
		text-align: center;
	}

	.verify-result.valid {
		background: linear-gradient(145deg, #f0fdf4 0%, #dcfce7 100%);
		border: 1px solid #86efac;
	}

	.verify-result.invalid {
		background: linear-gradient(145deg, var(--color-primary-50) 0%, var(--color-primary-100) 100%);
		border: 1px solid var(--color-primary-200);
	}

	.result-icon {
		align-items: center;
		animation: scaleIn var(--duration-slow) var(--ease-spring) 80ms backwards;
		border-radius: var(--radius-full);
		display: flex;
		height: 48px;
		justify-content: center;
		margin-bottom: var(--space-3);
		width: 48px;
	}

	.verify-result.valid .result-icon {
		background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%);
		box-shadow: 0 6px 16px rgba(34, 197, 94, 0.35);
		color: white;
	}

	.verify-result.invalid .result-icon {
		background: linear-gradient(135deg, var(--color-primary-400) 0%, var(--color-primary-500) 100%);
		box-shadow: 0 6px 16px rgba(238, 76, 44, 0.3);
		color: white;
	}

	.result-icon svg {
		height: 24px;
		width: 24px;
	}

	.result-title {
		animation: slideUp var(--duration-normal) var(--ease-out) 120ms backwards;
		font-size: 1.125rem;
		font-weight: 600;
		letter-spacing: -0.02em;
		margin: 0 0 var(--space-1);
	}

	.verify-result.valid .result-title {
		color: #166534;
	}

	.verify-result.invalid .result-title {
		color: var(--color-primary-700);
	}

	.result-desc {
		animation: slideUp var(--duration-normal) var(--ease-out) 160ms backwards;
		color: var(--color-slate-500);
		font-size: 0.8125rem;
		line-height: 1.5;
		margin: 0 0 var(--space-4);
		max-width: 240px;
	}

	.result-meta {
		animation: slideUp var(--duration-normal) var(--ease-out) 200ms backwards;
		display: flex;
		gap: var(--space-2);
	}

	.meta-tag {
		background: rgba(255, 255, 255, 0.8);
		border-radius: var(--radius-full);
		color: var(--color-slate-600);
		font-family: var(--font-mono);
		font-size: 0.6875rem;
		font-weight: 500;
		padding: var(--space-1) var(--space-3);
	}

	.verify-result.valid .meta-tag {
		background: rgba(255, 255, 255, 0.9);
		border: 1px solid #bbf7d0;
	}

	.verify-result.invalid .meta-tag {
		background: rgba(255, 255, 255, 0.9);
		border: 1px solid var(--color-primary-200);
	}
</style>
