import {Register} from "../../genes/Register.js"

const $global = Register.$global

export const HookClientEvent = 
Register.global("$hxEnums")["shared.liveview.HookClientEvent"] = 
{
	__ename__: "shared.liveview.HookClientEvent",
	
	ClipboardCopied: Object.assign((payload) => ({_hx_index: 0, __enum__: "shared.liveview.HookClientEvent", "payload": payload}), {_hx_name: "ClipboardCopied", __params__: ["payload"]}),
	HookPing: {_hx_name: "HookPing", _hx_index: 1, __enum__: "shared.liveview.HookClientEvent"}
}
HookClientEvent.__constructs__ = [HookClientEvent.ClipboardCopied, HookClientEvent.HookPing]
HookClientEvent.__empty_constructs__ = [HookClientEvent.HookPing]

export const HookEvents = Register.global("$hxClasses")["shared.liveview.HookEvents"] = 
class HookEvents {
	static clipboardCopied(message) {
		return HookClientEvent.ClipboardCopied({"message": (message == "") ? "Copied." : message});
	}
	static encodeClientPush(event) {
		switch (event._hx_index) {
			case 0:
				let payload = event.payload;
				return {"event": "clipboard_copied", "payload": HookEvents.encodeClipboardCopiedPayload(payload)};
				break
			case 1:
				return {"event": "ping", "payload": {}};
				break
			
		};
	}
	static encodeClipboardCopiedPayload(payload) {
		let wire = {};
		if (wire == null) {
			return wire;
		} else {
			wire["message"] = payload.message;
			return wire;
		};
	}
	static get __name__() {
		return "shared.liveview.HookEvents"
	}
	get __class__() {
		return HookEvents
	}
}

