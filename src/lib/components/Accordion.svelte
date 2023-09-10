<script lang="ts">
	import { fade } from 'svelte/transition';
	import { cubicInOut } from 'svelte/easing';

	let accordionOpen: boolean
</script>

<div class="relative mb-6">
	<button class="w-full cursor-pointer items-center border-b border-solid p-4 text-left font-semibold text-3xl transition-all ease-in"
			on:click={() => accordionOpen = !accordionOpen}>
		<span>
			<slot name='title' />
		</span>

		<i class="fa absolute right-0 pt-3 text-xs"
		   class:fa-plus={!accordionOpen}
		   class:fa-minus={accordionOpen}/>
	</button>

	{#if (accordionOpen)}
		<div class="transition-all duration-300 ease-in-out"
			 in:fade={{ duration: 500, easing: cubicInOut }}
			 out:fade={{ duration: 500, easing: cubicInOut }}>
			<div class="px-4 pt-4 text-sm leading-normal text-blue-gray-500/80">
				<slot name='content' />
			</div>
		</div>
	{/if}
</div>