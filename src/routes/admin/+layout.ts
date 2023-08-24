import { error, redirect } from '@sveltejs/kit';
import type { LayoutLoad } from './$types';

export const load: LayoutLoad = async ({ parent }) => {
	const { supabase, session, user } = await parent();
	if (!session)
		throw redirect(307, '/login');
	if (user === null || !user.isAdmin)
		throw error(401, "Unauthorized")
	return { supabase, session, user }
};
