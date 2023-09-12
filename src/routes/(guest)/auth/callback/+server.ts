import type { RequestHandler } from '@sveltejs/kit';
import { redirect } from '@sveltejs/kit';

/**
 * Request handler function for GET requests.
 * Responsible for handling the Supabase PKCE Authentication Workflow.
 *
 * @throws - Throws a redirect response with a status code of 301.
 */
export const GET: RequestHandler = async ({ url, locals: { supabase } }) => {
	const code = url.searchParams.get('code')

	if (code) {
		await supabase.auth.exchangeCodeForSession(code)
	}

	throw redirect(301, '/')
}