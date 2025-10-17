package;

import phoenix.Phoenix.Socket;
import phoenix.Phoenix.LiveView;

// Minimal result enum for pattern-matching success/error from Repo operations
enum Result<T, E> {
  Ok(value: T);
  Error(reason: E);
}

// Minimal Repo extern for delete operation returning a Result
extern class Repo {
  public static function delete(struct: Dynamic): Result<Dynamic, Dynamic>;
}

// Assigns are irrelevant for this shape test; use Dynamic
@:liveview
class DeleteLive {
  public function new() {}

  public static function mount(_params: Dynamic, _session: Dynamic, socket: Socket<Dynamic>): Dynamic {
    // basic assign to mark liveview usage consistently
    socket = LiveView.assign(socket, "count", 0);
    return {ok: socket};
  }

  // LiveView-style handler: delete by id, update UI list
  public static function delete_todo(id: Int, socket: Socket<Dynamic>): Dynamic {
    var todo: Dynamic = null; // placeholder struct
    switch (Repo.delete(todo)) {
      case Ok(deleted):
        // Intentionally pass the binder `deleted` here; the compiler pass should restore to `id`.
        var s2 = remove_todo_from_list(deleted, socket);
        return {noreply: s2};
      case Error(_):
        return {noreply: socket};
    }
  }

  static function remove_todo_from_list(id_like: Dynamic, socket: Socket<Dynamic>): Socket<Dynamic> {
    return socket;
  }
}
