@:native("TestAppWeb.ValueToIdLive")
@:liveview
class Main {
  public static function mount(params: elixir.types.Term, session: elixir.types.Term, socket: phoenix.Phoenix.Socket<{}>): phoenix.Phoenix.MountResult<{}> {
    return phoenix.Phoenix.MountResult.Ok(socket);
  }

  public static function handle_event(event: String, params: elixir.types.Term, socket: phoenix.Phoenix.Socket<{}>): phoenix.Phoenix.HandleEventResult<{}> {
    switch (event) {
      case "toggle_todo":
        // First arg Map.get(params, "value") should be normalized to id (int) by the transform.
        toggleTodo(elixir.ElixirMap.get(params, "value"), socket);
      default:
    }
    return phoenix.Phoenix.HandleEventResult.NoReply(socket);
  }

  static function toggleTodo(id: elixir.types.Term, socket: phoenix.Phoenix.Socket<{}>): Void {}
}
