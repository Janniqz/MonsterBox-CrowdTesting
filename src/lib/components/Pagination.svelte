<script lang="ts">
	export let page: number, pages: number;
</script>

<div class='flex justify-center items-center gap-2'>
	{#each Array(pages) as _, index (index)}
		<button on:click={() => page = index + 1}
				class:underline={page === index + 1}>{index + 1}</button>
	{/each}
</div>