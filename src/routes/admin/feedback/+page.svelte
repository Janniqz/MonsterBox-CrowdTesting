<script lang="ts">
	import type { PageData } from './$types';
	import HorizontalLine from '$components/HorizontalLine.svelte';
	import Pagination from '$components/Pagination.svelte';

	export let data: PageData
	let { supabase, promotions } = data;

	let promotionId: number;
	let page: number = 1;
	let pages: number;
	let feedbacks: { feedback_text: string, created_at: string }[] | null = null;

	$: (loadFeedback(promotionId, page))

	/**
	 * Loads feedback for a specific promotion and page.
	 *
	 * @param promotionId - The ID of the promotion.
	 * @param page - The current page number.
	 */
	async function loadFeedback(promotionId: number, page: number) {
		if (promotionId === -1 || promotionId == undefined) {
			feedbacks = null;
			pages = 0;
			return;
		}

		// Get Feedback for the selected Promotion ordered by its ID (newest at top)
		let { data: feedbackData } = await supabase
			.from('feedback')
			.select('feedback_text,created_at')
			.eq('promotion_id', promotionId)
			.order('feedback_id', { ascending: false })
			.range((page - 1) * 10, page * 10 - 1)

		// Get the total count of Feedbacks for this Promotion
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

<HorizontalLine/>

{#if feedbacks !== null && feedbacks.length !== 0}
	{#each feedbacks as feedback}
		<div class='border-4 border-gray-700 bg-gray-900 rounded-3xl text-white p-5 mb-5 break-words'>
			{new Date(feedback.created_at).toUTCString()}
			<HorizontalLine marginY='my-2'/>
			<span>{feedback.feedback_text}</span>
		</div>
	{/each}

	<HorizontalLine/>
	<Pagination {page} {pages}/>
{:else}
	<span class='text-white'>No feedback available :(</span>
{/if}