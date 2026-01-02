import {Register} from "../../genes/Register.js"

const $global = Register.$global

export const AutoFocusHook = Register.global("$hxClasses")["client.hooks.AutoFocusHook"] = 
class AutoFocusHook {
	static mounted(hook) {
		try {
			hook.el.focus();
		}catch (_g) {
		};
	}
	static get __name__() {
		return "client.hooks.AutoFocusHook"
	}
	get __class__() {
		return AutoFocusHook
	}
}

