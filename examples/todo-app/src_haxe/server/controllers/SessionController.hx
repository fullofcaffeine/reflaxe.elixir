package controllers;

import contexts.Accounts;
import elixir.ElixirMap;
import elixir.types.Term;
import haxe.functional.Result;
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
@:native("TodoAppWeb.SessionController")
@:controller
class SessionController {
    public static function create(conn: Conn<{}>, params: Term): Conn<{}> {
        var emailTerm: Term = ElixirMap.get(params, "email");
        var nameTerm: Term = ElixirMap.get(params, "name");

        var email: String = emailTerm != null ? cast emailTerm : "";
        var name: String = nameTerm != null ? cast nameTerm : "";

        if (StringTools.trim(email) == "" || StringTools.trim(name) == "") {
            return conn
                .putFlash("error", "Name and email are required.")
                .redirect("/login");
        }

        return switch (Accounts.getOrCreateUserForLogin(email, name)) {
            case Ok(user):
                conn
                    .putSession("user_id", user.id)
                    .putFlash("info", 'Signed in as ${user.name}.')
                    .redirect("/todos");
            case Error(error):
                {
                    // Ensure the bound error is used so generated Elixir compiles under --warnings-as-errors.
                    Std.string(error);
                    conn
                        .putFlash("error", "Could not sign in. Please check your details and try again.")
                        .redirect("/login");
                }
        };
    }

    public static function delete(conn: Conn<{}>, _params: Term): Conn<{}> {
        return conn
            .deleteSession("user_id")
            .putFlash("info", "Signed out.")
            .redirect("/");
    }
}
