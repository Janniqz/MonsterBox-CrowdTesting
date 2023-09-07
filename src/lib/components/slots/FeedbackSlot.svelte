<script lang="ts">
	import SlotBase from '$components/slots/SlotBase.svelte';

	export let promotion_name: string
	export let key_id: bigint
</script>

<SlotBase>
	{promotion_name} {key_id}
</SlotBase>