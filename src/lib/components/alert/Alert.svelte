<script lang="ts">
	import { fade } from "svelte/transition";
	import { removeAlert } from "./alertStore";
	import type { Alert } from "./alertStore";

	export let alertValues: Alert

	function handleDismiss() {
		removeAlert(alertValues)
	}
</script>

<div transition:fade class="relative flex w-96 h-10 mb-5 mx-auto px-4 border text-white rounded-lg {alertValues.success ? 'border-green-400/40 bg-green-500/40' : 'border-red-600/40 bg-red-500/40'}" role="alert">
	<div class="grid grid-cols-12 w-full content-center">
		<div class="col-span-11">
			<span class="pr-1 {alertValues.success ? 'text-green-600 fa-sharp fa-solid fa-check' : 'text-red-600 fa-regular fa-circle-xmark'}"></span>
			<span>{alertValues.message}</span>
		</div>
		<button class="col-span-1 fa-regular fa-xmark text-right" on:click={handleDismiss}></button>
	</div>
</div>