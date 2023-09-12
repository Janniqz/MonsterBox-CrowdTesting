import { writable } from "svelte/store";

export type Alert = {
	message: string,
	success: boolean
}

export const alertStore = writable<Alert | null>(null);

/**
 * Adds an alert to the alert store.
 *
 * @param message - The message for the alert.
 * @param success - Boolean indicating if the alert is a success or error alert.
 */
export function addAlert(message: string, success: boolean) {
	const alert: Alert = { message: message, success: success }
	alertStore.set(alert)
}

/**
 * Removes the current alert from the alert store.
 */
export function removeAlert() {
	alertStore.set(null)
}