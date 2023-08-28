<script lang="ts">
	import Accordion from '$components/Accordion.svelte';
	import { page } from '$app/stores';

	export let data = $page.data;

</script>

<div class="flex w-screen h-screen">
	<div class="ml-auto mr-auto mb-auto w-2/3">
		<Accordion>
			<span slot='title'>Available Promotions</span>
			<slot slot='content'>
				{#each data.running as { promotion_id, promotion_name, claimed }}
					{promotion_id} {promotion_name} {claimed}
				{/each}
			</slot>
		</Accordion>
		<Accordion>
			<span slot='title'>Awaiting Feedback</span>
			<span slot='content'>
				{#each data.feedback as { promotion_id, promotion_name, key_id }}
					{promotion_id} {promotion_name} {key_id}
				{/each}
			</span>
		</Accordion>
		<Accordion>
			<span slot='title'>Redeemed Keys</span>
			<span slot='content'>
				{#each data.redeemed as { promotion_name, key }}
					{promotion_name} {key}
				{/each}
			</span>
		</Accordion>
	</div>
</div>