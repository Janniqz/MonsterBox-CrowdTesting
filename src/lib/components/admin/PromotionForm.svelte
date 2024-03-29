<script lang="ts">
	import Modal from '$components/Modal.svelte';
	import HorizontalLine from '$components/HorizontalLine.svelte';
	import type { PostgrestSingleResponse, SupabaseClient } from '@supabase/supabase-js';

	export let supabase: SupabaseClient;
	export let promotionFormOpen: boolean;
	export let promotionEditTarget: {claimed_keys: number | null, created_at: string | null, description: string | null, expiration_date: string | null, feedback_ratio: number | null, name: string | null, promotion_id: number | null, total_keys: number | null} | null;
	export let formCallback: () => void;

	let promotionName: string, promotionDescription: string, promotionTemporary: boolean, promotionEndDate: string;
	let promotionExistingKeys: {key_id: number | null, key: string | null}[] | null = null;
	let promotionNewKeys: string[] = [];
	let promotionRemovedKeys: number[] = [];
	let promotionKeyInput: string = '';

	let promotionNameError: boolean, promotionEndDateError: boolean, promotionKeyInputError: boolean

	$: (updateFormFields(promotionEditTarget))
	$: (promotionNameError = !/\S/.test(promotionName))
	$: (promotionEndDateError = promotionTemporary && !promotionEndDate)
	$: (promotionKeyInputError = promotionKeyInput.length == 0 || /\s/.test(promotionKeyInput))

	/**
	 * Updates the form fields with the data from the selected Promotion.
	 *
	 * @param dataSource - The selected Promotion the information to update the form fields. If null fields will stay empty.
	 */
	async function updateFormFields(dataSource: {claimed_keys: number | null, created_at: string | null, description: string | null, expiration_date: string | null, feedback_ratio: number | null, name: string | null, promotion_id: number | null, total_keys: number | null} | null) {
		// If we have a selected Promotion, use its values. Otherwise, clear all fields.
		promotionName = dataSource?.name ?? ''
		promotionDescription = dataSource?.description ?? ''
		promotionTemporary = dataSource?.expiration_date !== null
		promotionEndDate = dataSource?.expiration_date ?? ''

		// Load the existing keys if needed
		if (dataSource !== null) {
			await loadExistingKeys(dataSource.promotion_id!).then(r => promotionExistingKeys = r)
		}
		else {
			promotionExistingKeys = null
		}

		promotionNewKeys = []
		promotionRemovedKeys = []
	}

	/**
	 * Loads existing keys for a given promotion ID.
	 *
	 * @param promotionId - The ID of the promotion.
	 * @returns - An array of key objects containing key_id and key properties.
	 */
	async function loadExistingKeys(promotionId: number) {
		let { data } = await supabase
			.from('keys')
			.select('key_id,key')
			.eq('promotion_id', promotionId)
		return data;
	}

	/**
	 * Tries to add a key to the 'promotionNewKeys' array if it doesn't already exist.
	 *
	 * @param key - The key to try to add.
	 */
	function tryAddKey(key: string) {
		// If the Key to be added is already present in the new / existing keys, don't do anything
		if (key.length == 0 || promotionNewKeys.includes(key) || !!promotionExistingKeys?.find(k => k.key == key))
			return

		// Assign promotionNewKeys to itself to trigger reactivity
		promotionNewKeys.push(key)
		promotionNewKeys = promotionNewKeys
	}

	/**
	 * Removes a key from either the promotionNewKeys or promotionExistingKeys array.
	 *
	 * @param key - The key to be removed.
	 * @param existing - A boolean indicating whether the key is from promotionExistingKeys or promotionNewKeys.
	 */
	function tryRemoveKey(key: string | null, existing: boolean) {
		// If no key is passed, don't do anything
		if (key === null || key.length == 0)
			return

		// If it's a new key, just remove it from the array
		if (!existing) {
			// Make sure the key actually exists
			if (!promotionNewKeys.includes(key))
				return;
			promotionNewKeys = promotionNewKeys.filter(k => k !== key)
		}
		// If it's an existing key, remove it from the array and save it for removal
		else {
			if (promotionExistingKeys === null)
				return;

			// Make sure the key actually exists
			let targetElement = promotionExistingKeys.find(k => k.key === key)
			if (targetElement === undefined)
				return;

			promotionRemovedKeys.push(targetElement.key_id!)
			promotionExistingKeys = promotionExistingKeys.filter(k => k.key_id !== targetElement!.key_id)
		}
	}

	/**
	 * Handles the saving of a promotion to a database.
	 * If the promotionEditTarget is not null, it updates the existing promotion.
	 * Otherwise, it creates a new promotion.
	 */
	async function handleSavePromotion() {
		let promotionData = {
			name: promotionName,
			description: promotionDescription,
			expiration_date: promotionTemporary ? promotionEndDate : null
		}

		let result: PostgrestSingleResponse<any[]>

		// If we have a selected Promotion, update it
		if (promotionEditTarget !== null) {
			result = await supabase
				.from('promotions')
				.update(promotionData)
				.eq('promotion_id', promotionEditTarget.promotion_id!)
				.select()
		}

		// Otherwise create a new one
		else {
			result = await supabase
				.from('promotions')
				.insert(promotionData)
				.select()
		}

		// If we got a result, update added / removed Keys
		if (result.data) {
			await updateKeys(result.data[0].promotion_id)
			formCallback()
		}
	}

	/**
	 * Adds / Removes keys for a specific promotion.
	 * @param promotionId - The ID of the promotion.
	 */
	async function updateKeys(promotionId: number) {
		if (promotionNewKeys.length !== 0) {
			let addKeys = []

			// Add the promotion_id to the new Keys for correct association
			for (const newKey of promotionNewKeys) {
				addKeys.push({promotion_id: promotionId, key: newKey})
			}

			// Bulk insert the new Keys
			await supabase
				.from('keys')
				.insert(addKeys)
		}

		if (promotionRemovedKeys.length !== 0) {
			// Bulk remove the Keys that should be removed
			// Makes sure that they actually belong to the target Promotion
			await supabase
				.from('keys')
				.delete()
				.in('key_id', promotionRemovedKeys)
				.eq('promotion_id', promotionId)
		}
	}
</script>

<Modal bind:modalOpen={promotionFormOpen}>
	<div class='flex justify-start items-start text-left w-full h-full'>
		<div class='w-full'>
			{#if promotionNameError}
				<span class='text-mb-red text-'>Invalid Name Input!</span><br/>
			{/if}
			<label for='promotionName' class='text-black'>Promotion Name</label><br/>
			<input bind:value={promotionName} required id='promotionName' type='text' class='text-black border border-gray-500 hover:border-green-500 focus-visible:border-green-500 rounded-md'>
			<HorizontalLine marginY='my-4'/>
			<span class='inline-block text-black text-2xl pb-2'>Settings</span><br/>
			<label for='promotionDescription' class='text-black'>Promotion Description</label><br/>
			<textarea bind:value={promotionDescription} required id='promotionDescription' placeholder='Description' rows='4' class='w-full whitespace-pre-line inline-block mb-2 text-black border border-gray-500 hover:border-green-500 focus-visible:border-green-500 rounded-md'/>
			<br/>
			<label for='promotionTemporary' class='text-black'>Does this Promotion have an end date?</label>
			<input bind:checked={promotionTemporary} id='promotionTemporary' type='checkbox'>
			{#if promotionTemporary}
				<br/>
				{#if promotionEndDateError}
					<span class='text-mb-red text-'>Invalid Date Input!</span><br/>
				{/if}
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
					{#if promotionKeyInputError}
						<span class='text-mb-red text-'>Invalid Key Input!</span><br/>
					{/if}
					<label for='promotionNewKey' class='text-black'>Add new Key</label>
					<input bind:value={promotionKeyInput} id='promotionNewKey' type='text' class='text-black border border-gray-500 rounded-md'>
					<button class='w-2/5 h-8 mt-2 bg-green-500 hover:bg-green-600 focus-visible:bg-green-600 text-white rounded-md transition ease-in-out duration-300'
							disabled={promotionKeyInputError}
							class:cursor-not-allowed={promotionKeyInputError}
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
				disabled={promotionNameError || promotionEndDateError}
				class:cursor-not-allowed={promotionNameError || promotionEndDateError}
				on:click={() => handleSavePromotion()}>
			Save
		</button>
		<button type="button" class="w-1/5 h-8 bg-red-600 hover:bg-red-700 focus-visible:bg-red-700 text-white rounded-md transition ease-in-out duration-300"
				on:click={() => promotionFormOpen = false}>Cancel
		</button>
	</svelte:fragment>
</Modal>