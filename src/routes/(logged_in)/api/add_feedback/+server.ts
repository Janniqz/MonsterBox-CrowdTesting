import { json, error } from '@sveltejs/kit';
import { PRIVATE_SUPABASE_SERVICE_KEY } from '$env/static/private';
import type { RequestHandler } from './$types';

export const POST: RequestHandler = async ({ request, locals, fetch }) => {
	const session = await locals.getSession();
	if (session === null)
		throw error(401, "Unauthorized!")

	const { promotion_id, key_id, feedbackText } = await request.json();
	const response = await fetch("https://oguaokmrlyqkjdjndihr.supabase.co/rest/v1/rpc/add_feedback", {
		method: 'POST',
		body: JSON.stringify({ user_id: session.user.id, target_promotion_id: promotion_id, target_key_id: key_id, feedback_text: feedbackText }),
		headers: {
			"Content-Type": "application/json",
			"apikey": PRIVATE_SUPABASE_SERVICE_KEY,
			"Authorization": "Bearer " + PRIVATE_SUPABASE_SERVICE_KEY
		},

	})
	const result = await response.json()
	return json({ data: result, error: !response.ok })
};