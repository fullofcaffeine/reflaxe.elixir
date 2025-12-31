package client.hooks;

import client.extern.PhoenixHookContext;
import client.utils.Theme;
import client.utils.ThemePreference;
import js.html.Element;
import js.html.Event;

class ThemeToggleHook {
  static inline var handlerField = "__todoappThemeToggleOnClick";

  static function labelFor(preference: ThemePreference): String {
    return switch (preference) {
      case ThemePreference.System: "System";
      case ThemePreference.Light: "Light";
      case ThemePreference.Dark: "Dark";
    };
  }

  static function updateLabel(root: Element, preference: ThemePreference): Void {
    root.setAttribute("data-theme-mode", preference);
    var label = root.querySelector("[data-theme-label]");
    if (label != null) {
      label.textContent = labelFor(preference);
    }
  }

  public static function mounted(ctx: PhoenixHookContext): Void {
    unbindClick(ctx);

    var preference = Theme.applyStoredOrDefault();
    updateLabel(ctx.el, preference);

    var handler = function(_event: Event) {
      var nextPreference = Theme.cycle(Theme.getStoredOrDefault());
      Theme.store(nextPreference);
      Theme.apply(nextPreference);
      updateLabel(ctx.el, nextPreference);
    };

    Reflect.setField(cast ctx.el, handlerField, handler);
    ctx.el.addEventListener("click", handler);
  }

  public static function destroyed(ctx: PhoenixHookContext): Void {
    unbindClick(ctx);
  }

  static function unbindClick(ctx: PhoenixHookContext): Void {
    var elementDynamic: Dynamic = cast ctx.el;
    if (!Reflect.hasField(elementDynamic, handlerField)) return;

    var existingHandler: Null<Event->Void> = cast Reflect.field(elementDynamic, handlerField);
    if (existingHandler != null) {
      ctx.el.removeEventListener("click", existingHandler);
    }
    Reflect.deleteField(elementDynamic, handlerField);
  }
}
