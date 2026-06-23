package;

import elixir.types.Term;
import phoenix.LiveStreams;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.LiveView;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Socket;

typedef Todo = {
	var id:Int;
	var title:String;
}

typedef StreamAssigns = {
	var todos:Array<Todo>;
	var notices:Array<String>;
}

/**
 * Typed LiveView stream token smoke test.
 *
 * WHAT
 * - Verifies `LiveStreams.of(...)` generates stream-name tokens from list-shaped
 *   assigns fields.
 *
 * WHY
 * - Streams should stay Phoenix-native while gaining Haxe type pairing between a
 *   stream name and its item shape.
 *
 * HOW
 * - Exercises `Socket<T>.stream`, `streamInsert`, and `streamDelete`.
 * - Keeps one raw `Phoenix.LiveView.stream(socket, "legacy_todos", ...)` call to
 *   prove the direct extern path remains source-compatible.
 */
@:native("TestAppWeb.StreamTokensLive")
@:liveview
class Main {
	public static function mount(_params:Term, _session:Term, socket:Socket<StreamAssigns>):MountResult<StreamAssigns> {
		var streams = LiveStreams.of(StreamAssigns);
		socket = socket.stream(streams.todos, seedTodos());
		socket = socket.stream(streams.notices, ["ready"]);
		socket = LiveView.stream(socket, "legacy_todos", seedTodos());
		return Ok(socket);
	}

	public static function handle_event(event:String, _params:Term, socket:Socket<StreamAssigns>):HandleEventResult<StreamAssigns> {
		var streams = LiveStreams.of(StreamAssigns);
		return switch (event) {
			case "add":
				NoReply(socket.streamInsert(streams.todos, todo(2, "Next")));
			case "delete":
				NoReply(socket.streamDelete(streams.todos, todo(1, "First")));
			case "notice":
				NoReply(socket.streamInsert(streams.notices, "Saved"));
			case _:
				NoReply(socket);
		};
	}

	public static function render(_assigns:StreamAssigns):String {
		return "<ul id=\"todos\" phx-update=\"stream\"></ul>";
	}

	static function seedTodos():Array<Todo> {
		return [todo(1, "First")];
	}

	static function todo(id:Int, title:String):Todo {
		return {
			id: id,
			title: title
		};
	}
}
