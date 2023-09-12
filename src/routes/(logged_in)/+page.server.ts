import type { PageServerLoad } from './$types'

/**
 * Loads data related to current Promotions and user-specific feedback and redemption data.
 */
export const load: PageServerLoad = async({ locals, depends }) => {
	depends('app:promotions');

	const supabase = locals.supabase

	let { data: runningPromotionData } = await supabase.rpc('get_running_promotions')
	let { data: awaitingFeedbackData } = await supabase.rpc('get_awaiting_feedback')
	let { data: redeemedData } = await supabase.rpc('get_redeemed')

	return {
		running: runningPromotionData,
		feedback: awaitingFeedbackData,
		redeemed: redeemedData
	}
}