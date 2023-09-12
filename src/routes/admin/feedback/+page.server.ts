import type { PageServerLoad } from './$types'

export const load: PageServerLoad = async({ locals }) => {
	const supabase = locals.supabase

	let { data: promotions } = await supabase.from("promotions").select("promotion_id,name")

	return {
		promotions: promotions
	}
}