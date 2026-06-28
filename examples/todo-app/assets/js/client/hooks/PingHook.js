import {HookEvents} from "../../shared/liveview/_HookEventsGenerated.js"
import {Register} from "../../genes/Register.js"

const $global = Register.$global

export const PingHook = Register.global("$hxClasses")["client.hooks.PingHook"] = 
class PingHook {
	static mounted(hook) {
		try {
			HookEvents.pushHookPing(hook);
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

