import { get, writable } from "svelte/store";
import type { Writable } from  "svelte/store";

export type Alert = {
	id: number,
	message: string,
	success: boolean
}

export const alertStore = writable<Alert[]>([]);
export const alertIncrement: Writable<number> = writable(0)

export function addAlert(message: string, success: boolean) {
	const index: number = get(alertIncrement)
	const alert: Alert = { id: index, message: message, success: success }
	alertStore.update(a => [...a, alert])
	alertIncrement.update(c => c + 1)
}

export function removeAlert(alert: Alert) {
	const index = get(alertStore).indexOf(alert)
	alertStore.update(a => [...a.slice(0, index), ...a.slice(index + 1)])
}