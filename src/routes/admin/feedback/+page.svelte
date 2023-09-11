<script lang="ts">
	import type { PageData } from './$types';

	export let data: PageData
	let { supabase, promotions } = data;

	let promotionId: number;
	let page: number = 1;
	let pages: number;
	let feedbacks: { feedback_text: string, created_at: string }[] | null = null;

	$: (load_feedback(promotionId, page))

	async function load_feedback(promotionId: number, page: number) {
		if (promotionId === -1 || promotionId == undefined) {
			feedbacks = null;
			pages = 0;
			return;
		}

		let { data: feedbackData } = await supabase
			.from('feedback')
			.select('feedback_text,created_at')
			.eq('promotion_id', promotionId)
			.range((page - 1) * 10, page * 10)
		let { count: feedbackCount } = await supabase
			.from('feedback')
			.select('*', { count: 'exact', head: true })
			.eq('promotion_id', promotionId)

		feedbacks = feedbackData;
		pages = Math.ceil((feedbackCount ?? 0) / 10);
	}

</script>

<label for='promotionSelect' class='inline-block align-middle text-2xl pr-2'>Target Promotion: </label>
<select id='promotionSelect' bind:value={promotionId} class="inline-block bg-gray-50 border text-sm rounded-lg w-1/5 p-2.5 dark:bg-gray-700 border-gray-600 placeholder-gray-400 text-white focus:ring-blue-500 focus:border-blue-500">
	<option disabled selected value=-1>None</option>
	{#if promotions !== null}
		{#each promotions as promotion}
			<option value={promotion.promotion_id}>{promotion.name}</option>
		{/each}
	{/if}
</select>

<hr class="h-px my-8 bg-gray-200 border-0 dark:bg-gray-700">

{#if feedbacks !== null && feedbacks.length !== 0}
	{#each feedbacks as feedback}
		<span class='text-white'>{feedback.feedback_text} {feedback.created_at}</span>
	{/each}

	<hr class="h-px my-8 bg-gray-200 border-0 dark:bg-gray-700">

	<div class='flex justify-center items-center'>
		{#each Array(pages) as _, index (index)}
			<button on:click={() => page = index + 1}>{index + 1}</button>
		{/each}
	</div>
{:else}
	<span class='text-white'>No feedback available :(</span>
{/if}