import {Register} from "../../genes/Register.js"

const $global = Register.$global

export const HookClientEvents = Register.hxClasses()["HookClientEvents"] =
class HookClientEvents {
	static pushClipboardCopied(hook, message) {
		if (hook.pushEvent != null) {
			hook.pushEvent("clipboard_copied", {"message": message});
		};
	}
	static pushHookPing(hook) {
		if (hook.pushEvent != null) {
			hook.pushEvent("ping", {});
		};
	}
	static get __name__() {
		return "HookClientEvents"
	}
	get __class__() {
		return HookClientEvents
	}
}
