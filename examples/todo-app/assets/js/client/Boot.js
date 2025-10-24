import {Register} from "../genes/Register.js"

/**
* Minimal, typed Phoenix LiveView hook registry for bootstrapping interactivity.
* Avoids Dynamic on public surfaces per No‑Dynamic policy; uses inline JS only
* at the boundary to call into the LiveView hook context (this.*).
*/
export const Boot = Register.global("$hxClasses")["client.Boot"] = 
class Boot {
	static main() {
		let hooks = {"AutoFocus": {"mounted": function () {
			this.el && this.el.focus && this.el.focus();
		}}, "Ping": {"mounted": function () {
			try { this.pushEvent && this.pushEvent('ping', {}) } catch (_) {} ;
		}}};
		window.Hooks = window.Hooks || hooks;
	}
	static get __name__() {
		return "client.Boot"
	}
	get __class__() {
		return Boot
	}
}

