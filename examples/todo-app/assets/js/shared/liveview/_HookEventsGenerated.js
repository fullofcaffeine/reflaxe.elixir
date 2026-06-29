import {Register} from "../../genes/Register.js"

const $global = Register.$global

export const HookEvents = Register.global("$hxClasses")["HookEvents"] = 
class HookEvents {
	static pushClipboardCopied(hook, message) {
		if (hook.pushEvent != null) {
			hook.pushEvent("clipboard_copied", { message : message});
		};
	}
	static pushHookPing(hook) {
		if (hook.pushEvent != null) {
			hook.pushEvent("ping", { });
		};
	}
	static get __name__() {
		return "HookEvents"
	}
	get __class__() {
		return HookEvents
	}
}

