import { redirect } from '@sveltejs/kit';
import type { LayoutLoad } from './$types';

/**
 * Function to handle layout load.
 *
 * @throws Throws an error and redirects to the homepage if a session exists.
 */
export const load: LayoutLoad = async ({ parent }) => {
	const { session } = await parent();
	if (session)
		throw redirect(307, '/');
};
