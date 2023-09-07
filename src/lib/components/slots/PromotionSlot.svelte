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

	let buttonText = promotion_claimed ? "Claimed" : "Claim"
	let buttonDisabled = promotion_claimed;

	const claimPromotion = async () => {
		if (promotion_claimed) {
			addAlert("You've already claimed a Key for this Promotion!", false)
			return
		}

		try
		{
			buttonText = "Claiming..."
			buttonDisabled = true

			const response = await data.supabase.rpc('claim_key', { promotion_id })
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

<SlotBase>
	{promotion_name} {promotion_description} {promotion_expiry_date}
	<button class="mx-auto w-36 h-8 border-2 outline-none rounded-3xl transition ease-in-out bg-transparent text-white cursor-pointer hover:bg-white focus-visible:bg-white hover:text-black duration-300"
			disabled={buttonDisabled}>{buttonText}</button>
</SlotBase>