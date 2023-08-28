<script lang="ts">
	import Accordion from '$components/Accordion.svelte';
	import { page } from '$app/stores';

	export let { feedback, redeemed, running } = $page.data;

</script>

<div class="flex w-screen h-screen">
	<div class="ml-auto mr-auto mb-auto w-2/3">
		<Accordion>
			<span slot='title'>Available Promotions</span>
			<slot slot='content'>
				{#if (running !== null)}
					{#each running as { promotion_id, promotion_name, promotion_description, claimed }}
						{promotion_id} {promotion_name} {promotion_description} {claimed}
					{/each}
				{/if}
			</slot>
		</Accordion>
		<Accordion>
			<span slot='title'>Awaiting Feedback</span>
			<span slot='content'>
				{#if (feedback !== null)}
					{#each feedback as { promotion_name, key_id }}
						{promotion_name} {key_id}
					{/each}
				{/if}
			</span>
		</Accordion>
		<Accordion>
			<span slot='title'>Redeemed Keys</span>
			<span slot='content'>
				{#if (redeemed !== null)}
					{#each redeemed as { promotion_name, key_id, feedback_given }}
						{promotion_name} {key_id} {feedback_given}
					{/each}
				{/if}
			</span>
		</Accordion>
	</div>
</div>