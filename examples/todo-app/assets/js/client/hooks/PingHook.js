import {HookClientEvents} from "../../shared/liveview/_HookClientEventsGenerated.js"
import {Register} from "../../genes/Register.js"

const $global = Register.$global

export const PingHook = Register.global("$hxClasses")["client.hooks.PingHook"] =
class PingHook {
	static mounted(hook) {
		try {
			HookClientEvents.pushHookPing(hook);
		}catch (_g) {
		};
	}
	static get __name__() {
		return "client.hooks.PingHook"
	}
	get __class__() {
		return PingHook
	}
}

