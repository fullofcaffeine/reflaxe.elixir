@:native("TestAppWeb.ValueDecodeLive")
@:liveview
class Main {
  public static function mount(params: elixir.types.Term, session: elixir.types.Term, socket: phoenix.Phoenix.Socket<{}>): phoenix.Phoenix.MountResult<{}> {
    return phoenix.Phoenix.MountResult.Ok(socket);
  }

  public static function handle_event(event: String, params: elixir.types.Term, socket: phoenix.Phoenix.Socket<{}>): phoenix.Phoenix.HandleEventResult<{}> {
    switch (event) {
      case "search_todos":
        // Historically, some LiveView payloads arrived as `%{"value" => <...>}`. The current pipeline
        // normalizes Haxe's `Map.get(params, "value")` default access to just `params`, matching the
        // typical LiveView handle_event/3 params shape (fields at the top level).
        performSearch(elixir.ElixirMap.get(params, "value"), socket);
      default:
    }
    return phoenix.Phoenix.HandleEventResult.NoReply(socket);
  }

  static function performSearch(payload: elixir.types.Term, socket: phoenix.Phoenix.Socket<{}>): Void {}
}
