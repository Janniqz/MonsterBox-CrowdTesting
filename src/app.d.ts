import { Session, SupabaseClient } from '@supabase/supabase-js';
import type { Database } from '$lib/supabaseTypes';

declare global {
	namespace App {
		// interface Error {}
		interface Locals {
			supabase: SupabaseClient<Database>;
			getSession(): Promise<Session | null>
		}
		interface PageData {
			supabase: SupabaseClient<Database>;
			session: Session | null;
		}
		// interface Platform {}
	}
}

export {};
