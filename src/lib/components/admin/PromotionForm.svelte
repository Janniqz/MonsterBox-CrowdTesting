<script lang="ts">
	import Modal from '$components/Modal.svelte';
	import HorizontalLine from '$components/HorizontalLine.svelte';
	import type { PostgrestSingleResponse, SupabaseClient } from '@supabase/supabase-js';

	export let supabase: SupabaseClient;
	export let promotionFormOpen: boolean;
	export let promotionEditTarget: {claimed_keys: number | null, created_at: string | null, description: string | null, expiration_date: string | null, feedback_ratio: number | null, name: string | null, promotion_id: number | null, total_keys: number | null} | null;
	export let formCallback: () => void;

	let promotionName: string, promotionDescription: string, promotionTemporary: boolean, promotionEndDate: string;
	let promotionExistingKeys: {key_id: number | null, key: string | null}[] | null
	let promotionNewKeys: string[]
	let promotionRemovedKeys: number[]
	let promotionKeyInput: string

	$: (updateFormFields(promotionEditTarget))

	// Updates the Form Fields with the values of the (possibly) selected Promotion for editing
	async function updateFormFields(dataSource: {claimed_keys: number | null, created_at: string | null, description: string | null, expiration_date: string | null, feedback_ratio: number | null, name: string | null, promotion_id: number | null, total_keys: number | null} | null) {
		promotionName = dataSource?.name ?? ''
		promotionDescription = dataSource?.description ?? ''
		promotionTemporary = dataSource?.expiration_date !== null
		promotionEndDate = dataSource?.expiration_date ?? ''

		if (dataSource !== null) {
			await loadExistingKeys(dataSource.promotion_id!).then(r => promotionExistingKeys = r)
		}
		else {
			promotionExistingKeys = null
		}

		promotionNewKeys = []
		promotionRemovedKeys = []
	}

	// Retrieves the existing Keys for the Promotion to be edited
	async function loadExistingKeys(promotion_id: number) {
		let { data } = await supabase
			.from('keys')
			.select('key_id,key')
			.eq('promotion_id', promotion_id)
		return data;
	}

	// Attempts to add a new Key to the Promotion. If it already exists in either the existing or new keys, doesn't do anything
	function tryAddKey(key: string) {
		if (key.length == 0 || promotionNewKeys.includes(key) || !!promotionExistingKeys?.find(k => k.key == key))
			return
		promotionNewKeys.push(key)
		promotionNewKeys = promotionNewKeys
	}

	// Attempts to remove a Key from the Promotion. If it doesn't exist in the new / existing Keys, doesn't do anything
	function tryRemoveKey(key: string | null, existing: boolean) {
		if (key === null || key.length == 0)
			return

		if (!existing) {
			if (!promotionNewKeys.includes(key))
				return;
			promotionNewKeys = promotionNewKeys.filter(k => k !== key)
		}
		else {
			if (promotionExistingKeys === null)
				return;

			let targetElement = promotionExistingKeys.find(k => k.key === key)
			if (targetElement === undefined)
				return;
			promotionRemovedKeys.push(targetElement.key_id!)
			promotionExistingKeys = promotionExistingKeys.filter(k => k.key_id !== targetElement!.key_id)
		}
	}

	// Creates / Updates a Promotion in the Database
	async function handleSavePromotion() {
		let promotionData = {
			name: promotionName,
			description: promotionDescription,
			expiration_date: promotionTemporary ? promotionEndDate : null
		}

		let result: PostgrestSingleResponse<any[]>
		if (promotionEditTarget !== null) {
			result = await supabase
				.from('promotions')
				.update(promotionData)
				.eq('promotion_id', promotionEditTarget.promotion_id!)
		.select()
		}
		else {
			result = await supabase
				.from('promotions')
				.insert(promotionData)
				.select()
				.limit(1)
		}

		if (result.data) {
			// Create newly added Keys
			await updateKeys(result.data[0].promotion_id)
			formCallback()
		}
	}

	// Updates the Keys in the database. If this is a new Promotion, all Keys will be added.
	// If it's an existing promotion, new keys are added and keys to be removed are deleted.
	async function updateKeys(promotion_id: number) {
		if (promotionNewKeys.length !== 0) {
			let addKeys = []
			for (const newKey of promotionNewKeys) {
				addKeys.push({promotion_id: promotion_id, key: newKey})
			}

			const { data, error } = await supabase
				.from('keys')
				.insert(addKeys)
				.select()
		}

		if (promotionRemovedKeys.length !== 0) {
			const { error } = await supabase
				.from('keys')
				.delete()
				.in('key_id', promotionRemovedKeys)
				.eq('promotion_id', promotion_id)
		}
	}
</script>

<Modal modalClose={promotionFormOpen}>
	<div class='flex justify-start items-start text-left w-full h-full'>
		<div class='w-full'>
			<label for='promotionName' class='text-black'>Promotion Name</label><br/>
			<input bind:value={promotionName} required id='promotionName' type='text' class='text-black border border-gray-500 hover:border-green-500 focus-visible:border-green-500 rounded-md'>
			<HorizontalLine marginY='my-4'/>
			<span class='inline-block text-black text-2xl pb-2'>Settings</span><br/>
			<label for='promotionDescription' class='text-black'>Promotion Description</label><br/>
			<textarea bind:value={promotionDescription} required id='promotionDescription' placeholder='Description' rows='4' class='w-full inline-block mb-2 text-black border border-gray-500 hover:border-green-500 focus-visible:border-green-500 rounded-md'/>
			<br/>
			<label for='promotionTemporary' class='text-black'>Does this Promotion have an end date?</label>
			<input bind:checked={promotionTemporary} id='promotionTemporary' type='checkbox'>
			{#if promotionTemporary}
				<br/>
				<label for='promotionEndDate' class='text-black'>Promotion End Date</label>
				<input bind:value={promotionEndDate} id='promotionEndDate' type='date' class='text-black border border-gray-500 hover:border-green-500 focus-visible:border-green-500 rounded-md'>
			{/if}
			<HorizontalLine marginY='my-4'/>
			<span class='inline-block text-black text-2xl pb-2'>Keys</span>
			<div class='flex divide-x-2 divide-gray-700 w-full h-32'>
				<div class='w-3/5 pr-2'>
					<ul class='overflow-y-scroll h-full border border-gray-500 rounded-md'>
						{#if promotionExistingKeys !== null}
							{#each promotionExistingKeys as promotionKey}
								<li class='text-black px-2'>
									<div class='w-full flex justify-between'>
										<div class='text-black'>{promotionKey.key}</div>
										<button class="fa-solid fa-xmark pt-1 text-black hover:text-mb-red focus-visible:text-mb-red transition ease-in-out duration-300"
												on:click={() => tryRemoveKey(promotionKey.key, true)}></button>
									</div>
								</li>
							{/each}
						{/if}
						{#each promotionNewKeys as promotionKey}
							<li class='text-black px-2'>
								<div class='w-full flex justify-between'>
									<div class='text-black'>{promotionKey}</div>
									<button class="fa-solid fa-xmark pt-1 text-black hover:text-mb-red focus-visible:text-mb-red transition ease-in-out duration-300"
											on:click={() => tryRemoveKey(promotionKey, false)}></button>
								</div>
							</li>
						{/each}
					</ul>
				</div>
				<div class='w-2/5 pl-2'>
					<label for='promotionNewKey' class='text-black'>Add new Key</label>
					<input bind:value={promotionKeyInput} id='promotionNewKey' type='text' class='text-black border border-gray-500 rounded-md'>
					<button class='w-2/5 h-8 mt-2 bg-green-500 hover:bg-green-600 focus-visible:bg-green-600 text-white rounded-md transition ease-in-out duration-300'
							on:click={() => {
									tryAddKey(promotionKeyInput)
									promotionKeyInput = ''
								}}>Add</button>
				</div>
			</div>
		</div>
	</div>

	<svelte:fragment slot='modalButtons'>
		<button slot='modalButtons' type="button" class="w-1/5 h-8 ml-3 bg-green-500 hover:bg-green-600 focus-visible:bg-green-600 text-white rounded-md transition ease-in-out duration-300"
				on:click={() => handleSavePromotion()}>
			Save
		</button>
		<button type="button" class="w-1/5 h-8 bg-red-600 hover:bg-red-700 focus-visible:bg-red-700 text-white rounded-md transition ease-in-out duration-300"
				on:click={() => promotionFormOpen = !promotionFormOpen}>Cancel
		</button>
	</svelte:fragment>
</Modal>