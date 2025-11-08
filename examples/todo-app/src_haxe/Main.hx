package;

/**
 * Minimal entrypoint to satisfy Haxe `-main` for custom Elixir target builds.
 * This class is not intended to be emitted; Reflaxe.Elixir generates files per
 * module listed in build-server.hxml. Keeping this empty avoids affecting output.
 */
class Main {
  public static function main():Void {}
}

