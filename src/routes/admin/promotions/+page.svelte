<script lang="ts">
	import type { PageData } from './$types';
	import HorizontalLine from '$components/HorizontalLine.svelte';
	import PromotionForm from '$components/admin/PromotionForm.svelte';
	import Pagination from '$components/Pagination.svelte';
	import { addAlert } from '$components/alert/alertStore';

	export let data: PageData
	let { supabase } = data;

	let promotions: {claimed_keys: number | null, created_at: string | null, description: string | null, expiration_date: string | null, feedback_ratio: number | null, name: string | null, promotion_id: number | null, total_keys: number | null}[] | null = null;
	let page: number = 1;
	let pages: number;

	// Form Variables
	let promotionFormOpen = false;
	let promotionEditTarget: {claimed_keys: number | null, created_at: string | null, description: string | null, expiration_date: string | null, feedback_ratio: number | null, name: string | null, promotion_id: number | null, total_keys: number | null} | null = null;

	$: (loadPromotions(page))
	$: if (!promotionFormOpen) promotionEditTarget = null;

	// Updates the displayed list of Promotions depending on the currently selected Page
	async function loadPromotions(page: number) {
		let { data: promotionData } = await supabase
			.from('promotion_admin_info')
			.select('*')
			.order('created_at', { ascending: false })
			.range((page - 1) * 10, page * 10 - 1)
		let { count: promotionCount } = await supabase
			.from('promotions')
			.select('*', { count: 'exact', head: true })

		promotions = promotionData
		pages = Math.ceil((promotionCount ?? 0) / 10);
	}

	async function onFormCallback() {
		// If we created a new Promotion, go back to the first page. Otherwise, just reload the current page.
		if (promotionEditTarget === null) {
			page = 1
			addAlert('Promotion created!', true)
		}
		else {
			addAlert('Promotion updated!', true)
		}

		promotionFormOpen = false;
		await loadPromotions(page);
	}

</script>

<div class='flex justify-end'>
	<button type="button" class="w-1/5 h-12 bg-green-500 hover:bg-green-600 focus-visible:bg-green-600 text-white rounded-md transition ease-in-out duration-300"
			on:click={() => promotionFormOpen = true}>
		New Promotion
	</button>
</div>

<HorizontalLine/>

{#if promotions !== null && promotions.length !== 0}
	{#each promotions as promotion}
		<div class='border-4 border-gray-700 bg-gray-900 rounded-3xl text-white p-5 mb-5 break-words'>
			<div class='flex w-full'>
				<div class='w-4/5'>
					<span class='text-2xl'>{promotion.name}</span>
				</div>
				<div class='flex w-1/5 justify-end'>
					<button type="button" class="w-full h-full bg-blue-500 hover:bg-blue-600 focus-visible:bg-blue-600 text-white rounded-md transition ease-in-out duration-300"
							on:click={() => {
								promotionEditTarget = promotion
								promotionFormOpen = true
							}}>
						Edit Promotion
					</button>
				</div>
			</div>
			<HorizontalLine marginY='my-2'/>
			<div class='flex divide-x-2 divide-gray-700 w-full'>
				<div class='w-4/5 pr-2'>
					<span>{promotion.description}</span>
				</div>
				<div class='w-1/5 pl-2'>
					<span>Expiration: {promotion.expiration_date ?? 'None'}</span><br/>
					<span>Keys: {promotion.claimed_keys} / {promotion.total_keys} (C / T)</span><br/>
					<span>Feedback Ratio: {(promotion.feedback_ratio ?? 1) * 100}%</span>
				</div>
			</div>
		</div>
	{/each}

	<HorizontalLine/>
	<Pagination {page} {pages}/>
{:else}
	<span class='text-white'>No promotions available :(</span>
{/if}

{#if promotionFormOpen}
	<PromotionForm {supabase} {promotionFormOpen} {promotionEditTarget} formCallback={onFormCallback}/>
{/if}