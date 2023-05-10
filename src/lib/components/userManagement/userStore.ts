import { get, writable } from "svelte/store";
import type { Writable } from  "svelte/store";
import type { SupabaseClient, AuthChangeEvent, Session } from '@supabase/supabase-js';
import { invalidate } from '$app/navigation';
import { addAlert } from '../alert/alertStore';

export type User = {
	id: string,
	isAdmin: boolean,
}

export let sessionStore: Writable<Session | null> = writable(null);

export async function setSession(supabase: SupabaseClient, event: AuthChangeEvent, session: Session | null) {
	const currentSession = get(sessionStore);
	if (session == null)
	{
		if (currentSession != null)
		{
			sessionStore.set(null)
			await invalidate('supabase:auth')
		}
		return;
	}

	if (session.access_token !== currentSession?.access_token) {
		sessionStore.set(session);
		await invalidate('supabase:auth')

		// Send fitting Alert
		if (event == 'SIGNED_IN')
			addAlert("Successfully signed in!", true)
		else if (event == 'SIGNED_OUT')
			addAlert("Successfully signed out!", true)
	}
}

export async function getSessionUser(supabase: SupabaseClient, session: Session | null) {
	if (!session)
		return null;

	const sessionUser = session.user;

	let user: User | null = null;
	const profile = await supabase.from('profiles').select().eq('id', sessionUser.id).limit(1).single();
	if (profile.data !== null)
	{
		user = { id: sessionUser.id, isAdmin: profile.data['role'] === 'admin' }
		return user;
	}
	else
		return null;
}