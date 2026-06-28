import {HookClientEvent} from "./HookEvents.js"
import {Register} from "../../genes/Register.js"

const $global = Register.$global

export const HookEvents = Register.global("$hxClasses")["HookEvents"] = 
class HookEvents {
	static encode(event) {
		switch (event._hx_index) {
			case 0:
				let message = event.message;
				let wire = {};
				if (wire != null) {
					wire["message"] = message;
				};
				return {"event": "clipboard_copied", "payload": wire};
				break
			case 1:
				let wire1 = {};
				return {"event": "ping", "payload": wire1};
				break
			
		};
	}
	static push(hook, event) {
		let event1 = HookEvents.encode(event);
		if (hook.pushEvent != null) {
			hook.pushEvent(event1.event, event1.payload);
		};
	}
	static pushClipboardCopied(hook, message) {
		HookEvents.push(hook, HookClientEvent.ClipboardCopied(message));
	}
	static pushHookPing(hook) {
		HookEvents.push(hook, HookClientEvent.HookPing);
	}
	static get __name__() {
		return "HookEvents"
	}
	get __class__() {
		return HookEvents
	}
}

