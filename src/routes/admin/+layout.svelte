<script lang="ts">
	import Alerts from '$components/alert/Alerts.svelte';
	import Header from '$components/Header.svelte';
</script>

<Header/>
<Alerts/>

<div class="flex w-screen h-screen">
	<div class="ml-auto mr-auto mb-auto w-2/3">
		<slot/>
	</div>
</div>