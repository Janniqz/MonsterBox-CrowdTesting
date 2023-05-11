<script lang="ts">
	import { alertStore } from "./alertStore";
	import Alert from "$components/alert/Alert.svelte";
</script>

<div class="absolute w-full mx-auto top-[10%]">
	{#if ($alertStore)}
		<svelte:component this={Alert} alertValues={$alertStore}/>
	{/if}
</div>