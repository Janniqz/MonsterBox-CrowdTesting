<script lang="ts">
	import SlotBase from '$components/slots/SlotBase.svelte';

	export let promotion_name: string
	export let key: string
	export let feedback_given: boolean
</script>

<SlotBase>
	{promotion_name} {key} {feedback_given}
</SlotBase>