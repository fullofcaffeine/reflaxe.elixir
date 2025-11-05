@:native("TestAppWeb.ValueDecodeLive")
@:liveview
class Main {
  public static function mount(params:Dynamic, session:Dynamic, socket:Dynamic):Dynamic {
    return { status: "ok", socket: socket };
  }

  public static function handle_event(event:String, params:Dynamic, socket:Dynamic):Dynamic {
    switch (event) {
      case "search_todos":
        // First arg uses params.value; transform will decode when it is a binary query string.
        performSearch(params.value, socket);
      default:
    }
    return { status: "noreply", socket: socket };
  }

  static function performSearch(payload:Dynamic, socket:Dynamic):Void {}
}

