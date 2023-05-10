<script lang="ts">
	import { PUBLIC_PAGE_BASE } from '$env/static/public'
	import { Alerts } from '$components/alert';
	import { addAlert } from '$components/alert/alertStore';
	import PageData = App.PageData;

	export let data: PageData;

	let buttonText = "Login"
	let loading = false
	let email: string

	const handleLogin = async () => {
		try
		{
			buttonText = "Sending..."
			loading = true
			const response = await data.supabase.auth.signInWithOtp({
				email: email,
				options: {
					emailRedirectTo: PUBLIC_PAGE_BASE + 'login_request'
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
			addAlert("An error occurred. Please try again later!", false)
		}
		finally
		{
			loading = false
		}
	}
</script>

<Alerts/>

<div class="flex w-screen h-screen">
	<div class="m-auto">
		<img class="mb-3" src="/imgs/logos/MonsterBox_Text.svg" alt="MonsterBox">
		<form class="flex flex-col text-center m-auto" on:submit|preventDefault="{handleLogin}">
			<input class="bg-gray-800 border border-transparent outline-none rounded py-2 px-3 mb-3 transition focus-visible:border-mb-red hover:border-mb-red duration-300" type="email" placeholder="mail@email.com" bind:value="{email}" />
			<input type="submit"
						 class="mx-auto w-36 h-8 border-2 outline-none rounded-3xl transition ease-in-out bg-transparent text-white cursor-pointer hover:bg-white focus-visible:bg-white hover:text-black focus-visible:text-black duration-300"
						 value={buttonText}
						 disabled={loading}/>
		</form>
	</div>
</div>