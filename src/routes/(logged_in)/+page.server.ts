import type { PageServerLoad } from './$types'

export const load: PageServerLoad = async({ locals }) => {
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