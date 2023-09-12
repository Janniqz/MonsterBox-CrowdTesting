<script lang="ts">
	import { fade } from 'svelte/transition';
	import { cubicInOut } from 'svelte/easing';

	export let modalClose: boolean;
</script>

<div in:fade={{ duration: 500, easing: cubicInOut }}
	 out:fade={{ duration: 500, easing: cubicInOut }}>
	<div class="relative z-10">
		<div class="fixed inset-0 bg-gray-700 bg-opacity-75"/>

		<div class="fixed inset-0 w-screen">
			<div class="flex h-full justify-center items-center">
				<div class="overflow-hidden rounded-lg bg-white my-8 w-full max-w-lg">
					<div class="flex justify-center items-center text-center p-6 pb-4">
						<slot/>
					</div>
					<div class="bg-gray-50 py-3 flex flex-row-reverse px-6">
						<slot name='modalButtons'>
							<button type="button" class="inline-flex justify-center pt-1 ml-auto w-1/5 h-8 border-2 bg-transparent border-black hover:bg-black hover:text-white focus-visible:bg-black focus-visible:text-white text-black outline-none rounded-3xl transition ease-in-out duration-300"
									on:click={() => modalClose = !modalClose}>Close
							</button>
						</slot>
					</div>
				</div>
			</div>
		</div>
	</div>

</div>