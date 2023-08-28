<script lang="ts">
	import { page } from '$app/stores';
	export let data = $page.data;
</script>

<nav class='w-screen h-60 py-2'>
	<div class='px-5 max-w-screen-2xl mx-auto'>
		<div class='flex justify-between'>
			<img class='h-16' src="/imgs/logos/MonsterBox_Text.svg" alt='MonsterBox'>
			<div class='flex items-center'>
				<a href='/logout' class='text-3xl mx-5 px-2 py-1 rounded text-black transition duration-300 bg-white focus-visible:bg-gray-300 hover:bg-gray-300'>Logout</a>
				{#if (data.user.isAdmin)}
					<a href='/admin' class='text-3xl ml-5 px-2 py-1 rounded text-black transition duration-300 bg-mb-red focus-visible:bg-red-600 hover:bg-red-600'>Admin Zone</a>
				{/if}
			</div>
		</div>
	</div>
</nav>