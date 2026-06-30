package phoenix_hx_todo_hx.controllers;

import StringTools;
import elixir.types.Term;
import phoenix.Params;
import phoenix_hx_todo_hx.contexts.Accounts;
import phoenix_hx_todo_hx.contexts.Todos;
import plug.Conn;

/**
 * Session controller for the RailsHx-inspired demo entry flow.
 *
 * WHAT
 * - Creates and clears the Plug session used by LiveView.
 *
 * WHY
 * - Phoenix LiveViews receive a LiveView session map, not the Plug session itself.
 *   A controller action is the normal place to mutate the browser session.
 */
@:controller
class SessionController {
	public static function create(conn:Conn<{}>, params:Term):Conn<{}> {
		var name = stringParam(params, "name", "Guest Workspace");
		var email = stringParam(params, "email", "guest@example.test");

		if (StringTools.trim(name) == "" || StringTools.trim(email) == "") {
			return conn.putFlash("error", "Name and email are required.").redirect("/");
		}

		return switch (Accounts.getOrCreateDemoUser(name, email)) {
			case Ok(user):
				Todos.seedDefaultsForUser(user);
				conn.putSession("user_id", user.id).putFlash("info", 'Signed in as ${user.name}.').redirect("/todos");
			case Error(_):
				conn.putFlash("error", "Could not open the demo workspace.").redirect("/");
		};
	}

	public static function delete(conn:Conn<{}>, params:Term):Conn<{}> {
		return conn.deleteSession("user_id").putFlash("info", "Signed out.").redirect("/");
	}

	static function stringParam(params:Term, key:String, fallback:String):String {
		return Params.getStringDefault(params, key, fallback);
	}
}
