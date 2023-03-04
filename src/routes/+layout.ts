import { invalidate } from '$app/navigation';
import { PUBLIC_SUPABASE_ANON_KEY, PUBLIC_SUPABASE_URL } from '$env/static/public';
import { createSupabaseLoadClient } from '@supabase/auth-helpers-sveltekit';
import type { LayoutLoad } from './$types';
import type { Database, User } from '$lib/supabaseTypes';

export const load: LayoutLoad = async ({ fetch, data, depends }) => {
	depends('supabase:auth');

	const supabase = createSupabaseLoadClient<Database>({
		supabaseUrl: PUBLIC_SUPABASE_URL,
		supabaseKey: PUBLIC_SUPABASE_ANON_KEY,
		event: { fetch },
		serverSession: data.session,

		onAuthStateChange() {
			invalidate('supabase:auth');
		}
	});

	const { data: { session } } = await supabase.auth.getSession();
	const sUser = session?.user;

	let user: User | null = null;
	if (sUser !== undefined)
	{
		const profile = await supabase.from('profiles').select().eq('id', sUser?.id).limit(1).single();
		if (profile.data !== null)
		{
			user = { id: sUser.id, isAdmin: profile.data['role'] === 'admin' }
		}
	}

	return { supabase, session, user };
};
