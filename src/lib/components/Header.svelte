<script lang="ts">
	import { page } from '$app/stores';

	export let data = $page.data;
	export let isAdminPath = $page.url.pathname.includes('/admin');
</script>

<nav class='w-screen h-60 py-2'>
	<div class='px-5 max-w-screen-2xl mx-auto'>
		<div class='flex justify-between'>
			<img class='h-16' src="/imgs/logos/MonsterBox_Text.svg" alt='MonsterBox'>
			<div class='flex items-center w-2/3'
				 class:justify-between={isAdminPath}
				 class:justify-end={!isAdminPath}>
				{#if (isAdminPath)}
					<div>
						<a href='/' class='text-3xl mx-5 px-2 py-1 transition duration-300 focus-visible:text-gray-400 hover:text-gray-400'>Home</a>
						<a href='/admin/promotions' class='text-3xl mx-5 px-2 py-1 transition duration-300 focus-visible:text-gray-400 hover:text-gray-400'>Promotions</a>
						<a href='/admin/feedback' class='text-3xl mx-5 px-2 py-1 transition duration-300 focus-visible:text-gray-400 hover:text-gray-400'>Feedback</a>
					</div>
				{/if}
				<div>
					<a href='/logout' class='text-3xl mx-5 px-2 py-1 rounded text-black transition duration-300 bg-white focus-visible:bg-gray-300 hover:bg-gray-300'>Logout</a>
					{#if (data.user && data.user.isAdmin)}
						<a href='/admin' class='text-3xl ml-5 px-2 py-1 rounded text-black transition duration-300 bg-mb-red focus-visible:bg-red-600 hover:bg-red-600'>Admin Zone</a>
					{/if}
				</div>
			</div>
		</div>
	</div>
</nav>