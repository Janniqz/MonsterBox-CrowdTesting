import { Session, SupabaseClient } from '@supabase/supabase-js';
import type { Database } from '$lib/supabaseTypes';
import type { User } from '$components/userManagement/userStore';

declare global {
	namespace App {
		// interface Error {}
		interface Locals {
			supabase: SupabaseClient<Database>;
			getSession(): Promise<Session | null>
		}
		interface PageData {
			session: Session | null;
			user?: User | null;
		}
		// interface Platform {}
	}
}

export {};
