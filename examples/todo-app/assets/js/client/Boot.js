import {Register} from "../genes/Register.js"
import {Theme} from "./utils/Theme.js"
import {ThemeToggleHook} from "./hooks/ThemeToggleHook.js"
import {PingHook} from "./hooks/PingHook.js"
import {CopyToClipboardHook} from "./hooks/CopyToClipboardHook.js"
import {AutoFocusHook} from "./hooks/AutoFocusHook.js"

const $global = Register.$global

/**
* Minimal, typed Phoenix LiveView hook registry for bootstrapping interactivity.
* Avoids raw JS strings; uses typed Haxe that compiles via Genes.
* Only uses dynamic interop at the Phoenix Hook boundary (`this` context).
*/
export const Boot = Register.global("$hxClasses")["client.Boot"] = 
class Boot {
	static buildHooks() {
		let hooks = {};
		hooks["AutoFocus"] = {"mounted": function () {
			AutoFocusHook.mounted(this);
		}};
		hooks["Ping"] = {"mounted": function () {
			PingHook.mounted(this);
		}};
		hooks["CopyToClipboard"] = {"mounted": function () {
			CopyToClipboardHook.mounted(this);
		}};
		hooks["ThemeToggle"] = {"mounted": function () {
			ThemeToggleHook.mounted(this);
		}, "destroyed": function () {
			ThemeToggleHook.destroyed(this);
		}};
		return hooks;
	}
	static main() {
		Theme.applyStoredOrDefault();
		let hooks = Boot.buildHooks();
		window.Hooks = Object.assign(window.Hooks || {}, hooks);
	}
	static get __name__() {
		return "client.Boot"
	}
	get __class__() {
		return Boot
	}
}

