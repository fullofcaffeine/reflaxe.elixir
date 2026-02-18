package;

import elixir.types.Term;
import phoenix.AssignKeys;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Socket;

typedef SocketAssigns = {
	var count:Int;
	var search_query:String;
}

/**
 * Socket assign extension smoke test.
 *
 * WHAT
 * - Verifies assign helper macros on `Socket<T>` without creating a local `LiveSocket` variable.
 *
 * WHY
 * - `Socket<T>` is the canonical LiveView callback surface. We want concise callback code while
 *   preserving assign field validation and Phoenix-faithful runtime output.
 *
 * HOW
 * - Exercises default selector style (`assign`, `assignNew`, `update`) and typed-key style
 *   (`assignKey`, `updateKey`) through `AssignKeys.of(...)`.
 */
@:native("TestAppWeb.SocketAssignExtensionsLive")
@:liveview
class Main {
	public static function mount(_params:Term, _session:Term, socket:Socket<SocketAssigns>):MountResult<SocketAssigns> {
		var keys = AssignKeys.of(SocketAssigns);
		socket = socket.assign({
			count: 0,
			search_query: ""
		});
		socket = socket.assignKey(keys.count, 1);
		socket = socket.update(_.count, (n) -> n + 1);
		socket = socket.assignNew(_.search_query, () -> "initial");
		return Ok(socket);
	}

	public static function handle_event(event:String, params:Term, socket:Socket<SocketAssigns>):HandleEventResult<SocketAssigns> {
		var keys = AssignKeys.of(SocketAssigns);
		return switch (event) {
			case "search":
				var query:Null<String> = cast Reflect.field(params, "q");
				NoReply(socket.assignKey(keys.search_query, query != null ? query : ""));
			case "inc":
				NoReply(socket.updateKey(keys.count, (n) -> n + 1));
			case _:
				NoReply(socket);
		};
	}

	public static function render(assigns:SocketAssigns):String {
		return "<div>socket-assign-extensions</div>";
	}
}
