<script lang="ts">
	export let targetURL: string;
</script>

<div class="relative mb-6">
	<a class="w-full inline-block border-b border-solid p-4 text-left font-semibold text-3xl" href={targetURL}>
		<slot/>
	</a>
</div>