<script lang="ts">
	import type { PageData } from './$types'

	export let data: PageData;
</script>

Hello {data.user.id}.
Admin: {data.user.isAdmin}