<script lang="ts">
	import { alertStore } from "./alertStore";
	import { flip } from 'svelte/animate';
	import Alert from "$components/alert/Alert.svelte";
</script>

<div class="absolute w-full mx-auto top-[10%]">
	{#each $alertStore as alert (alert.id)}
		<div animate:flip>
			<svelte:component this={Alert} alertValues={alert}/>
		</div>
	{/each}
</div>