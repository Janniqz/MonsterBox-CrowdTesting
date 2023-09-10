<script lang="ts">
	import SlotBase from '$components/slots/SlotBase.svelte';
	import { addAlert } from '$components/alert/alertStore';
	import type { PageData } from './$types';

	export let data: PageData;

	export let promotion_id: bigint
	export let promotion_name: string
	export let promotion_description: string
	export let promotion_expiry_date: Date
	export let promotion_claimed: boolean
	export let promotion_total_keys: number
	export let promotion_unclaimed_keys: number

	let buttonText = promotion_claimed ? "Claimed" : promotion_unclaimed_keys === 0 ? "No Keys remaining" : "Claim"
	let buttonDisabled = (promotion_claimed || promotion_unclaimed_keys === 0);

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

			const response = await data.supabase.rpc('claim_key', { target_promotion_id: promotion_id })
			if (response.error)
				throw response.error

			const { success, error_message, claimed_key } = response.data
			if (success)
			{
				buttonText = "Claimed"
				addAlert("Key claimed! Add a modal here :)" + claimed_key, true)
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
			<span class='text-lg break-words'>
				{promotion_description}
			</span>
		</div>
		<div class='text-right'>
			<span class='text-2xl'>{promotion_unclaimed_keys} / {promotion_total_keys} Keys remaining</span><br/>
			<span class='text-xl'>Ends: {promotion_expiry_date}</span><br/>
			<button class="mx-auto mt-2 w-full h-8 border-2 outline-none rounded-3xl transition ease-in-out bg-transparent duration-300"
					disabled={buttonDisabled}
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