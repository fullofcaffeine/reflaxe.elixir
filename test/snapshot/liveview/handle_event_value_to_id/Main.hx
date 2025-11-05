@:native("TestAppWeb.ValueToIdLive")
@:liveview
class Main {
  public static function mount(params:Dynamic, session:Dynamic, socket:Dynamic):Dynamic {
    return { status: "ok", socket: socket };
  }

  public static function handle_event(event:String, params:Dynamic, socket:Dynamic):Dynamic {
    switch (event) {
      case "toggle_todo":
        // First arg params.value should be normalized to id (int) by the transform.
        toggleTodo(params.value, socket);
      default:
    }
    return { status: "noreply", socket: socket };
  }

  static function toggleTodo(id:Dynamic, socket:Dynamic):Void {}
}

