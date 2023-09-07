<script lang="ts">
	import { Alerts } from '$components/alert';
	import { addAlert } from '$components/alert/alertStore';
	import { fade } from 'svelte/transition';
	import type { PageData } from './$types';
	import { onMount } from 'svelte';
	import { page } from '$app/stores';

	export let data: PageData;

	let buttonText = "Login"
	let buttonDisabled = false;
	let email: string

	$: emailError = email == undefined || !/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/.test(email);

	const handleLogin = async () => {
		if (emailError)
			return;

		try
		{
			buttonText = "Sending..."
			buttonDisabled = true
			const response = await data.supabase.auth.signInWithOtp({
				email: email,
				options: {
					emailRedirectTo: `${location.origin}/auth/callback`
				}
			})

			if (response.error)
				throw response.error

			buttonText = "Sent!"
			addAlert("Magic Link sent. Check your Emails!", true)
		}
		catch (error)
		{
			buttonText = "Sending failed"
			buttonDisabled = false;
			addAlert("An error occurred. Please try again later!", false)
		}
	}

	onMount(() => {
		let params = new URLSearchParams($page.url.hash.substring(1));
		if (params.has('error')) {
			addAlert(params.get('error_description')!, false);
		}
	})
</script>

<Alerts/>

<div class="flex w-screen h-screen">
	<div class="m-auto">
		<img class="mb-3 w-80" src="/imgs/logos/MonsterBox_Text.svg" alt="MonsterBox">
		<form class="flex flex-col text-center m-auto" on:submit|preventDefault="{handleLogin}">
			<p>
				{#if emailError}
					<span class="text-mb-red" transition:fade>
						Please enter a valid email address!
					</span>
				{:else}
					<span>​</span>
				{/if}
			</p>

			<input id='email'
				   type="email"
				   class="bg-gray-800 border outline-none rounded py-2 px-3 mb-5 transition focus-visible:border-mb-red hover:border-mb-red duration-300"
				   class:border-transparent={emailError}
				   class:focus-visible:border-mb-red={emailError}
				   class:hover:border-mb-red={emailError}
				   class:border-green-400={!emailError}
				   placeholder="mail@email.com"
				   bind:value="{email}" />
			<input type="submit"
				   class="mx-auto w-36 h-8 border-2 outline-none rounded-3xl transition ease-in-out bg-transparent text-white cursor-pointer hover:bg-white focus-visible:bg-white hover:text-black focus-visible:text-black duration-300"
				   value={buttonText}
				   disabled={buttonDisabled}/>
		</form>
	</div>
</div>