<script lang="ts">
	import type { LayoutData } from './$types';
	import { onMount } from 'svelte';

	export let data: LayoutData;

	$: ({ supabase } = data);

	onMount(() => {
		supabase.auth.signOut();
	})
</script>

<div class="flex w-screen h-screen">
	<div class="m-auto">
		<div class="w-12 h-12 rounded-full animate-spin border-4 border-solid border-white border-t-transparent"></div>
	</div>
</div>