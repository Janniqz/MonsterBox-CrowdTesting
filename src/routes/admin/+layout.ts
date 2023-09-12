import { error, redirect } from '@sveltejs/kit';
import type { LayoutLoad } from './$types';

/**
 * Represents a function that retrieves the layout load information.
 *
 * @throws {Error} - Throws an error if the session is not available or the user is not an admin.
 */
export const load: LayoutLoad = async ({ parent }) => {
	const { supabase, session, user } = await parent();
	if (!session)
		throw redirect(307, '/login');
	if (user === null || !user.isAdmin)
		throw error(401, "Unauthorized")
	return { supabase, session, user }
};
