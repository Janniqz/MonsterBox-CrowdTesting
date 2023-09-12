import { PUBLIC_SUPABASE_ANON_KEY, PUBLIC_SUPABASE_URL } from '$env/static/public';
import { createSupabaseLoadClient } from '@supabase/auth-helpers-sveltekit';
import type { LayoutLoad } from './$types';
import type { Database } from '$lib/supabaseTypes';
import { getSessionUser } from '$components/userManagement/userStore';

/**
 * Loads the Root Layout.
 * Makes sure that all Locals are available, including the Supabase Client, session, and user.
 */
export const load: LayoutLoad = async ({ fetch, data, depends }) => {
	depends('supabase:auth');

	const supabase = createSupabaseLoadClient<Database>({
		supabaseUrl: PUBLIC_SUPABASE_URL,
		supabaseKey: PUBLIC_SUPABASE_ANON_KEY,
		event: { fetch },
		serverSession: data.session
	});

	const { data: { session } } = await supabase.auth.getSession();
	const user = await getSessionUser(supabase, session);

	return { supabase, session, user };
};
