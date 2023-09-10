<script lang="ts">
	import SlotBase from '$components/slots/SlotBase.svelte';

	export let promotion_name: string
	export let key: string
	export let feedback_given: boolean
</script>

<SlotBase>
	<div class='flex justify-between'>
		<div class='w-1/2'>
			<span class='text-2xl'>{promotion_name}</span><br>
		</div>
		<div class='text-right'>
			<span class='text-2xl'>{key}</span><br/>
			<span class='text-xl text-green'>
				Feedback Given:
				<span class:text-green-600={feedback_given}
					  class:text-red-600={!feedback_given}>
					{feedback_given ? "Yes" : "No"}
				</span>
			</span>
		</div>
	</div>
</SlotBase>