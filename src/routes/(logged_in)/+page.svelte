<script lang="ts">
	import Accordion from '$components/Accordion.svelte';
	import { page } from '$app/stores';
	import PromotionSlot from '$components/slots/PromotionSlot.svelte';
	import FeedbackSlot from '$components/slots/FeedbackSlot.svelte';
	import RedeemedSlot from '$components/slots/RedeemedSlot.svelte';

	export let { feedback, redeemed, running } = $page.data;

</script>

<div class="flex w-screen h-screen">
	<div class="ml-auto mr-auto mb-auto w-2/3">
		<Accordion>
			<span slot='title'>Available Promotions</span>
			<svelte:fragment slot='content'>
				{#if (Array.isArray(running) && running.length)}
					{#each running as promotionData}
						<PromotionSlot data={$page.data} {...promotionData}/>
					{/each}
				{:else}
					No running Promotions!
				{/if}
			</svelte:fragment>
		</Accordion>
		<Accordion>
			<span slot='title'>Awaiting Feedback</span>
			<svelte:fragment slot='content'>
				{#if (Array.isArray(feedback) && feedback.length)}
					{#each feedback as feedbackData}
						<FeedbackSlot data={$page.data} {...feedbackData}/>
					{/each}
				{:else}
					There are no promotions awaiting feedback!
				{/if}
			</svelte:fragment>
		</Accordion>
		<Accordion>
			<span slot='title'>Redeemed Keys</span>
			<svelte:fragment slot='content'>
				{#if (Array.isArray(redeemed) && redeemed.length)}
					{#each redeemed as redeemedData}
						<RedeemedSlot {...redeemedData} />
					{/each}
				{:else}
					You have not redeemed any Keys yet!
				{/if}
			</svelte:fragment>
		</Accordion>
	</div>
</div>