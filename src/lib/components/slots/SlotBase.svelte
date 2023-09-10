<script lang="ts">
	export let borderClasses = "focus-visible:border-green-500 hover:border-green-500"
</script>

<div class="bg-gray-800 border outline-none rounded py-2 px-3 transition {borderClasses} duration-300">
	<slot/>
</div>