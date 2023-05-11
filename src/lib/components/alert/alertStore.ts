import { writable } from "svelte/store";

export type Alert = {
	message: string,
	success: boolean
}

export const alertStore = writable<Alert | null>(null);

export function addAlert(message: string, success: boolean) {
	const alert: Alert = { message: message, success: success }
	alertStore.set(alert)
}

export function removeAlert() {
	alertStore.set(null)
}