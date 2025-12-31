package client.utils;

import js.Browser;
import js.html.MediaQueryList;

class Theme {
  static inline var storageKey = "todo_app_theme";

  static function getMediaQuery(): Null<MediaQueryList> {
    return Browser.window != null ? Browser.window.matchMedia("(prefers-color-scheme: dark)") : null;
  }

  public static function prefersDark(): Bool {
    var media = getMediaQuery();
    return media != null && media.matches;
  }

  public static function getStored(): Null<ThemePreference> {
    try {
      var storage = Browser.window != null ? Browser.window.localStorage : null;
      if (storage == null) return null;
      return ThemePreference.parse(storage.getItem(storageKey));
    } catch (_e: Dynamic) {
      return null;
    }
  }

  public static function getStoredOrDefault(): ThemePreference {
    return getStored() ?? ThemePreference.System;
  }

  public static function store(preference: ThemePreference): Void {
    try {
      var storage = Browser.window != null ? Browser.window.localStorage : null;
      if (storage == null) return;
      storage.setItem(storageKey, preference);
    } catch (_e: Dynamic) {}
  }

  public static function clearStored(): Void {
    try {
      var storage = Browser.window != null ? Browser.window.localStorage : null;
      if (storage == null) return;
      storage.removeItem(storageKey);
    } catch (_e: Dynamic) {}
  }

  public static function apply(preference: ThemePreference): Void {
    var root = Browser.document != null ? Browser.document.documentElement : null;
    if (root == null) return;

    var dark = switch (preference) {
      case ThemePreference.Dark: true;
      case ThemePreference.Light: false;
      case ThemePreference.System: prefersDark();
    };

    if (dark) {
      root.classList.add("dark");
    } else {
      root.classList.remove("dark");
    }

    root.setAttribute("data-theme", preference);
  }

  public static function applyStoredOrDefault(): ThemePreference {
    var preference = getStoredOrDefault();
    apply(preference);
    return preference;
  }

  public static function cycle(preference: ThemePreference): ThemePreference {
    return switch (preference) {
      case ThemePreference.System: ThemePreference.Light;
      case ThemePreference.Light: ThemePreference.Dark;
      case ThemePreference.Dark: ThemePreference.System;
    };
  }
}
