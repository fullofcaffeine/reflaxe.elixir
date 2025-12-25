@:native("TestAppWeb.ValueToIdLive")
@:liveview
class Main {
  public static function mount(params: elixir.types.Term, session: elixir.types.Term, socket: phoenix.Phoenix.Socket<{}>): phoenix.Phoenix.MountResult<{}> {
    return phoenix.Phoenix.MountResult.Ok(socket);
  }

  public static function handle_event(event: String, params: elixir.types.Term, socket: phoenix.Phoenix.Socket<{}>): phoenix.Phoenix.HandleEventResult<{}> {
    switch (event) {
      case "toggle_todo":
        // The current pipeline treats `Map.get(params, "value")` as a legacy default and normalizes
        // it to just `params` (matching the common LiveView params shape). Apps that want typed id
        // extraction should do so explicitly (or via framework helpers), rather than relying on
        // a late pass that guesses payload structure.
        toggleTodo(elixir.ElixirMap.get(params, "value"), socket);
      default:
    }
    return phoenix.Phoenix.HandleEventResult.NoReply(socket);
  }

  static function toggleTodo(id: elixir.types.Term, socket: phoenix.Phoenix.Socket<{}>): Void {}
}
