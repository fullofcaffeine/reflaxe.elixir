import {Register} from "../../genes/Register.js"

const $global = Register.$global

export const PingHook = Register.global("$hxClasses")["client.hooks.PingHook"] = 
class PingHook {
	static mounted(hook) {
		try {
			if (hook.pushEvent != null) {
				hook.pushEvent("ping", {});
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

