<script lang="ts">
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import { addAlert } from '$components/alert/alertStore';
	import { goto } from '$app/navigation';

	onMount(() => {
		let params = new URLSearchParams($page.url.hash.substring(1));
		if (params.has('error')) {
			addAlert(params.get('error_description')!, false);
			goto('/login')
		}
	})

</script>

<div class="flex w-screen h-screen">
	<div class="m-auto">
		<div class="w-12 h-12 rounded-full animate-spin border-4 border-solid border-white border-t-transparent"></div>
	</div>
</div>