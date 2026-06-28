import {Register} from "../../genes/Register.js"

const $global = Register.$global

/**
* Shared LiveView hook events for the todo app.
*
* WHAT
* - Declares client-pushed hook event names and payload shapes once for both
*   frontend Haxe compiled to JS with Genes and backend Haxe compiled to
*   Phoenix LiveView.
*
* WHY
* - LiveView hooks are a front/back boundary. The generated `HookEvents`
*   companion keeps hook pushes and server dispatchers in sync without
*   handwritten payload codecs.
*/
export const HookClientEvent = 
Register.global("$hxEnums")["shared.liveview.HookClientEvent"] = 
{
	__ename__: "shared.liveview.HookClientEvent",
	
	ClipboardCopied: Object.assign((message) => ({_hx_index: 0, __enum__: "shared.liveview.HookClientEvent", "message": message}), {_hx_name: "ClipboardCopied", __params__: ["message"]}),
	HookPing: {_hx_name: "HookPing", _hx_index: 1, __enum__: "shared.liveview.HookClientEvent"}
}
HookClientEvent.__constructs__ = [HookClientEvent.ClipboardCopied, HookClientEvent.HookPing]
HookClientEvent.__empty_constructs__ = [HookClientEvent.HookPing]
