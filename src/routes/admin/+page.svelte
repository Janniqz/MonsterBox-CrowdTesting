<script>
	import CategoryButton from '$components/admin/CategoryButton.svelte';
</script>

<div class="flex w-screen h-screen">
	<div class="ml-auto mr-auto mb-auto w-2/3">
		<CategoryButton targetURL='/admin/promotions'>
			Promotions
		</CategoryButton>
		<CategoryButton targetURL='/admin/feedback'>
			Feedback
		</CategoryButton>
	</div>
</div>