@:native("TestAppWeb.ValueDecodeLive")
@:liveview
class Main {
  public static function mount(params: elixir.types.Term, session: elixir.types.Term, socket: phoenix.Phoenix.Socket<{}>): phoenix.Phoenix.MountResult<{}> {
    return phoenix.Phoenix.MountResult.Ok(socket);
  }

  public static function handle_event(event: String, params: elixir.types.Term, socket: phoenix.Phoenix.Socket<{}>): phoenix.Phoenix.HandleEventResult<{}> {
    switch (event) {
      case "search_todos":
        // First arg uses Map.get(params, "value"); transform will decode when it is a binary query string.
        performSearch(elixir.ElixirMap.get(params, "value"), socket);
      default:
    }
    return phoenix.Phoenix.HandleEventResult.NoReply(socket);
  }

  static function performSearch(payload: elixir.types.Term, socket: phoenix.Phoenix.Socket<{}>): Void {}
}
