import { json, error } from '@sveltejs/kit';
import { PRIVATE_SUPABASE_SERVICE_KEY } from '$env/static/private';
import type { RequestHandler } from './$types';

/**
 * Process a POST request and claim a Key for the current User using Supabase REST API via the Supabase Service User.
 *
 * @async
 * @returns - The JSON response object containing the result and error information.
 * @throws - If the user is not authorized.
 */
export const POST: RequestHandler = async ({ request, locals, fetch }) => {
	// Sanity check that the User is actually logged in
	const session = await locals.getSession();
	if (session === null)
		throw error(401, "Unauthorized!")

	const { promotion_id } = await request.json();
	const response = await fetch("https://oguaokmrlyqkjdjndihr.supabase.co/rest/v1/rpc/claim_key", {
		method: 'POST',
		body: JSON.stringify({ user_id: session.user.id, target_promotion_id: promotion_id }),
		headers: {
			"Content-Type": "application/json",
			"apikey": PRIVATE_SUPABASE_SERVICE_KEY,
			"Authorization": "Bearer " + PRIVATE_SUPABASE_SERVICE_KEY
		},

	})
	const result = await response.json()
	return json({ data: result, error: !response.ok })
};