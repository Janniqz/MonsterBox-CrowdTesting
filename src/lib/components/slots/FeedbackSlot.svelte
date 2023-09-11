<script lang="ts">
	import SlotBase from '$components/slots/SlotBase.svelte';
	import { addAlert } from '$components/alert/alertStore';
	import { fade } from 'svelte/transition';
	import { cubicInOut } from 'svelte/easing';
	import Modal from '$components/Modal.svelte';
	import { invalidate } from '$app/navigation';

	export let promotion_name: string
	export let promotion_id: number
	export let key_id: number

	let accordionOpen: boolean

	let buttonText = "Send"
	let buttonDisabled = false;
	let feedbackText: string

	let feedbackModelOpen = false;

	$: feedbackError = feedbackText == undefined || feedbackText === "";
	$: if (feedbackModelOpen == false) { invalidate('app:promotions') }

	const sendFeedback = async () => {
		try {
			buttonText = "Sending..."
			buttonDisabled = true

			const request = await fetch('/api/add_feedback', {
				method: 'POST',
				body: JSON.stringify({ promotion_id, key_id, feedbackText })
			})
			const response = await request.json()
			if (response.error)
				throw response.error

			if (response.data) {
				buttonText = "Sent"
				feedbackModelOpen = true;
			} else {
				buttonText = "Sending failed"
				addAlert("Feedback was already given for this Key!", false)
			}
		} catch (error) {
			buttonText = "Sending failed"
			buttonDisabled = false;
			addAlert("An error occurred. Please try again later!", false)
		}
	}
</script>

<SlotBase>
	<button class="flex justify-between text-left w-full cursor-pointer text-2xl transition-all ease-in"
			on:click={() => accordionOpen = !accordionOpen}>
		<span class='w-1/2'>{promotion_name}</span>
		<i class="text-right text-sm pt-1.5 fa"
		   class:fa-plus={!accordionOpen}
		   class:fa-minus={accordionOpen}/>
	</button>

	{#if (accordionOpen)}
		<form class="flex flex-col text-center m-auto transition-all duration-300 ease-in-out"
			  in:fade={{ duration: 500, easing: cubicInOut }}
			  out:fade={{ duration: 500, easing: cubicInOut }}
			  on:submit|preventDefault="{sendFeedback}">
			{#if feedbackError}
				<p class='text-left'>
					<span class="text-mb-red" transition:fade>
						Please enter your feedback
					</span>
				</p>
			{/if}

			<textarea id='feedbackText'
					  class="w-full bg-gray-800 border outline-none rounded py-2 px-3 mb-5 transition duration-300"
					  rows='5'
					  class:focus-visible:border-mb-red={feedbackError}
					  class:hover:border-mb-red={feedbackError}
					  class:border-green-400={!feedbackError}
					  bind:value="{feedbackText}" /><br/>
			<input type="submit"
				   class="mx-auto w-1/5 content-center h-8 border-2 outline-none rounded-3xl transition ease-in-out bg-transparent text-white cursor-pointer hover:bg-white focus-visible:bg-white hover:text-black focus-visible:text-black duration-300"
				   value={buttonText}
				   disabled={buttonDisabled}/>
		</form>
	{/if}
</SlotBase>

{#if feedbackModelOpen}
	<Modal bind:modalClose={feedbackModelOpen}>
		<div>
			<span class='inline-block text-3xl transform -scale-x-100'>🎉</span>
			<span class='text-2xl font-bold text-black'>Thanks for your feedback!</span>
			<span class='inline-block text-3xl'>🎉</span>

			<br/>

			<span class='text-black'>We really appreciate it!</span>
		</div>
	</Modal>
{/if}