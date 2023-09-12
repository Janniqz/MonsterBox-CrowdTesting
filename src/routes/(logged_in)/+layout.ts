import { redirect } from '@sveltejs/kit';
import type { LayoutLoad } from './$types';

/**
 * Loads layout information.
 *
 * @throws {object} - Throws a redirect object if the user is not logged in.
 */
export const load: LayoutLoad = async ({ parent }) => {
	const { supabase, session, user } = await parent();
	if (!session)
		throw redirect(307, '/login');
	return { supabase, session, user }
};
