package client.hooks;

import phoenix.live_view.HookContext;
import client.utils.Theme;
import client.utils.ThemePreference;
import js.html.DOMElement;
import js.html.Event;
import js.lib.WeakMap;

class ThemeToggleHook {
	static final handlers = new WeakMap<Event->Void>();

	static function labelFor(preference:ThemePreference):String {
		return switch (preference) {
			case ThemePreference.System: "System";
			case ThemePreference.Light: "Light";
			case ThemePreference.Dark: "Dark";
		};
	}

	static function updateLabel(root:DOMElement, preference:ThemePreference):Void {
		root.setAttribute("data-theme-mode", preference);
		var label = root.querySelector("[data-theme-label]");
		if (label != null) {
			label.textContent = labelFor(preference);
		}
	}

	public static function mounted(ctx:HookContext):Void {
		unbindClick(ctx);

		var preference = Theme.applyStoredOrDefault();
		updateLabel(ctx.el, preference);

		var handler = function(_event:Event) {
			var nextPreference = Theme.cycle(Theme.getStoredOrDefault());
			Theme.store(nextPreference);
			Theme.apply(nextPreference);
			updateLabel(ctx.el, nextPreference);
		};

		handlers.set(ctx.el, handler);
		ctx.el.addEventListener("click", handler);
	}

	public static function destroyed(ctx:HookContext):Void {
		unbindClick(ctx);
	}

	static function unbindClick(ctx:HookContext):Void {
		var existingHandler = handlers.get(ctx.el);
		if (existingHandler != null) {
			ctx.el.removeEventListener("click", existingHandler);
			handlers.delete(ctx.el);
		}
	}
}
