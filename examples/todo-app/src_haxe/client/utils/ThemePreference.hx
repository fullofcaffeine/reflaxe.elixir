package client.utils;

enum abstract ThemePreference(String) from String to String {
  var System = "system";
  var Light = "light";
  var Dark = "dark";

  public static function parse(value: Null<String>): Null<ThemePreference> {
    return switch (value) {
      case "system": System;
      case "light": Light;
      case "dark": Dark;
      default: null;
    };
  }
}

