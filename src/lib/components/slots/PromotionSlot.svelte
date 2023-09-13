<script lang="ts">
	import SlotBase from '$components/slots/SlotBase.svelte';
	import { addAlert } from '$components/alert/alertStore';
	import Modal from '$components/Modal.svelte';
	import { invalidate } from '$app/navigation';

	export let promotion_id: number
	export let promotion_name: string
	export let promotion_description: string
	export let promotion_expiry_date: string
	export let promotion_claimed: boolean
	export let promotion_total_keys: number
	export let promotion_unclaimed_keys: number

	let buttonText = promotion_claimed ? "Claimed" : promotion_unclaimed_keys === 0 ? "No Keys remaining" : "Claim"
	let buttonDisabled = (promotion_claimed || promotion_unclaimed_keys === 0);

	let claimModalOpen = false;
	let claimedKey: string

	/**
	 * Claims a promotion key.
	 *
	 * If the promotion has already been claimed, an alert is displayed.
	 * If there are no remaining keys for the promotion, an alert is displayed.
	 * Otherwise, an API request is made to claim the key.
	 *
	 * If the claim is successful, the button text is updated to "Claimed" and the claim modal is opened.
	 * If the claim fails, an alert is displayed.
	 * If an error occurs during the claim process, an alert is displayed.
	 */
	const claimPromotion = async () => {
		if (promotion_claimed) {
			addAlert("You've already claimed a Key for this Promotion!", false)
			return
		}

		if (promotion_unclaimed_keys === 0) {
			addAlert("There are no remaining keys for this Promotion!", false)
			return
		}

		try
		{
			buttonText = "Claiming..."
			buttonDisabled = true

			// Send a request to the API to avoid the user having to modify sensitive tables
			const request = await fetch('/api/claim_key', {
				method: 'POST',
				body: JSON.stringify({ promotion_id })
			})
			const response = await request.json()
			if (response.error)
				throw response.error

			// Extract the required data from the result
			const { success, error_message, claimed_key } = response.data
			if (success)
			{
				buttonText = "Claimed"
				claimedKey = claimed_key;
				claimModalOpen = true;
				await invalidate('app:promotions')
			}
			else
			{
				buttonText = "Claiming failed"
				addAlert(error_message, false)
			}
		}
		catch (error)
		{
			buttonText = "Claiming failed"
			buttonDisabled = false;
			addAlert("An error occurred. Please try again later!", false)
		}
	}
</script>

<SlotBase borderClasses={buttonDisabled ? "focus-visible:border-mb-red hover:border-mb-red" : "focus-visible:border-green-500 hover:border-green-500"}>
	<div class='flex justify-between'>
		<div class='w-1/2'>
			<span class='text-2xl'>{promotion_name}</span><br>
			<span class='text-lg whitespace-pre-line break-words'>
				{promotion_description}
			</span>
		</div>
		<div class='text-right'>
			<span class='text-2xl'>{promotion_unclaimed_keys} / {promotion_total_keys} Keys remaining</span><br/>
			<span class='text-xl'>Ends: {promotion_expiry_date ?? "Never!"}</span><br/>
			<button class="mx-auto mt-2 w-full h-8 border-2 outline-none rounded-3xl transition ease-in-out duration-300"
					disabled={buttonDisabled}
					class:bg-transparent={!buttonDisabled}
					class:text-white={!buttonDisabled}
					class:cursor-pointer={!buttonDisabled}
					class:hover:border-white={!buttonDisabled}
					class:hover:bg-white={!buttonDisabled}
					class:hover:text-black={!buttonDisabled}
					class:focus-visible:border-white={!buttonDisabled}
					class:focus-visible:bg-white={!buttonDisabled}
					class:focus-visible:text-black={!buttonDisabled}
					class:border-gray-500={buttonDisabled}
					class:bg-gray-500={buttonDisabled}
					class:text-gray-800={buttonDisabled}
					class:cursor-not-allowed={buttonDisabled}
					on:click={claimPromotion}>
				{buttonText}
			</button>
		</div>
	</div>
</SlotBase>

{#if claimModalOpen}
	<Modal bind:modalOpen={claimModalOpen}>
		<div>
			<span class='text-2xl font-bold text-black'>Thanks for participating!</span><br/>
			<span class='inline-block text-xl text-black my-3'>{claimedKey}</span><br/>
			<span class='text-black'>Please make sure to send us some feedback when you're done playing!</span><br/>
			<a class="inline-block pt-1 mx-auto mt-2 w-1/2 h-8 border-2 bg-transparent border-black hover:bg-black hover:text-white focus-visible:bg-black focus-visible:text-white text-black outline-none rounded-3xl transition ease-in-out duration-300"
			   href='https://store.steampowered.com/account/registerkey?key={claimedKey}'
			   target='_blank'>
				Redeem
			</a>
		</div>
	</Modal>
{/if}