import { redirect } from '@sveltejs/kit';
import type { LayoutLoad } from './$types';

export const load: LayoutLoad = async ({ parent }) => {
	const { supabase, session, user } = await parent();
	if (!session)
		throw redirect(307, '/login');
	return { supabase, session, user }
};
