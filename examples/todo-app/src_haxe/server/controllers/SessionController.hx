package controllers;

import contexts.Accounts;
import elixir.types.Term;
import haxe.functional.Result;
import phoenix.Params;
import plug.Conn;
import StringTools;

/**
 * SessionController
 *
 * WHAT
 * - Handles demo sign-in/sign-out via the Plug session.
 *
 * WHY
 * - LiveViews receive a string-keyed "LiveView session" map. We persist auth state
 *   in the Plug session (`:user_id`) and derive the LiveView session via
 *   `TodoAppWeb.live_session/1`.
 *
 * HOW
 * - `create/2` find-or-creates a user by email and stores `:user_id` in the session.
 * - `delete/2` clears `:user_id`.
 */
// @:controller: marks this module as a Phoenix controller for HTTP actions.
@:controller
class SessionController {
	public static function create(conn:Conn<{}>, params:Term):Conn<{}> {
		// Direct helper style: one Phoenix param read plus a default stays clearer
		// as ordinary Haxe, and the compiler lowers it to the same Params call.
		var email = Params.getStringDefault(params, "email", "");
		var name = Params.getStringDefault(params, "name", "");

		if (StringTools.trim(email) == "" || StringTools.trim(name) == "") {
			return conn.putFlash("error", "Name and email are required.").redirect("/login");
		}

		return switch (Accounts.getOrCreateUserForLogin(email, name)) {
			case Ok(user):
				conn.putSession("user_id", user.id).putFlash("info", 'Signed in as ${user.name}.').redirect("/todos");
			case Error(_):
				{
					conn.putFlash("error", "Could not sign in. Please check your details and try again.").redirect("/login");
				}
		};
	}

	public static function delete(conn:Conn<{}>, params:Term):Conn<{}> {
		return conn.deleteSession("user_id").putFlash("info", "Signed out.").redirect("/");
	}
}
