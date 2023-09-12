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

/**
 * Sets the session for the Supabase client based on the provided parameters.
 *
 * @param supabase - The Supabase client instance.
 * @param event - The authentication change event.
 * @param session - The session object to set. Use `null` to clear the session.
 *
 * @return - A promise that resolves once the session is set or cleared.
 */
export async function setSession(supabase: SupabaseClient, event: AuthChangeEvent, session: Session | null) {
	const currentSession = get(sessionStore);
	if (session == null)
	{
		if (currentSession != null)
		{
			sessionStore.set(null)
			if (event == 'SIGNED_OUT')
				addAlert("Successfully signed out!", true)
		}
		return;
	}

	if (session.access_token !== currentSession?.access_token) {
		sessionStore.set(session);
	}
}

/**
 * Retrieves the session user from the Supabase client and session.
 *
 * @param supabase - The Supabase client.
 * @param session - The session object representing the user's session.
 * @returns The session user, or null if the session is null or the user does not have a profile.
 */
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