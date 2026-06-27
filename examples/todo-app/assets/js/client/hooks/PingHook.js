import {HookEvents, HookClientEvent} from "../../shared/liveview/HookEvents.js"
import {Register} from "../../genes/Register.js"

const $global = Register.$global

export const PingHook = Register.global("$hxClasses")["client.hooks.PingHook"] = 
class PingHook {
	static mounted(hook) {
		try {
			let event = HookEvents.encodeClientPush(HookClientEvent.HookPing);
			if (hook.pushEvent != null) {
				hook.pushEvent(event.event, event.payload);
			};
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

