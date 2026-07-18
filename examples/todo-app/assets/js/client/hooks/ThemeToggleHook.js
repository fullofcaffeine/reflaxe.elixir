import {Theme} from "../utils/Theme.js"
import {Register} from "../../genes/Register.js"

const $global = Register.$global

export const ThemeToggleHook = Register.hxClasses()["client.hooks.ThemeToggleHook"] =
class ThemeToggleHook {
	static labelFor(preference) {
		switch (preference) {
			case "dark":
				return "Dark";
				break
			case "light":
				return "Light";
				break
			case "system":
				return "System";
				break
		};
	}
	static updateLabel(root, preference) {
		root.setAttribute("data-theme-mode", preference);
		let label = root.querySelector("[data-theme-label]");
		if (label != null) {
			label.textContent = ThemeToggleHook.labelFor(preference);
		};
	}
	static mounted(ctx) {
		ThemeToggleHook.unbindClick(ctx);
		let preference = Theme.applyStoredOrDefault();
		ThemeToggleHook.updateLabel(ctx.el, preference);
		let handler = function (_event) {
			let nextPreference = Theme.cycle(Theme.getStoredOrDefault());
			Theme.store(nextPreference);
			Theme.apply(nextPreference);
			ThemeToggleHook.updateLabel(ctx.el, nextPreference);
		};
		ThemeToggleHook.handlers.set(ctx.el, handler);
		ctx.el.addEventListener("click", handler);
	}
	static destroyed(ctx) {
		ThemeToggleHook.unbindClick(ctx);
	}
	static unbindClick(ctx) {
		let existingHandler = ThemeToggleHook.handlers.get(ctx.el);
		if (existingHandler != null) {
			ctx.el.removeEventListener("click", existingHandler);
			ThemeToggleHook.handlers["delete"](ctx.el);
		};
	}
	static get __name__() {
		return "client.hooks.ThemeToggleHook"
	}
	get __class__() {
		return ThemeToggleHook
	}
}


ThemeToggleHook.handlers = new WeakMap()