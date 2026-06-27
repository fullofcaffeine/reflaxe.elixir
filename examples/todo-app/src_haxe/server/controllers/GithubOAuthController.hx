package controllers;

import contexts.Accounts;
import elixir.types.Term;
import haxe.functional.Result;
import phoenix.Params;
import plug.Conn;
import plug.CSRFProtection;
import server.services.GithubIdentity;
import server.services.GithubOAuth;

/**
 * GithubOAuthController
 *
 * WHAT
 * - Optional GitHub OAuth login endpoints for the todo-app showcase.
 *
 * WHY
 * - Demonstrates third-party auth integration (controller redirect + callback) while
 *   keeping the existing offline demo sign-in flow.
 *
 * HOW
 * - `github/2` starts OAuth by redirecting to GitHub with a session-stored state token.
 * - `github_callback/2` validates state, exchanges the code for user info, then stores
 *   `:user_id` in the Plug session (same mechanism as SessionController).
 */
// @:native (class): pins the generated Elixir module name to match Phoenix/Ecto runtime expectations.
@:native("TodoAppWeb.GithubOAuthController")
// @:controller: marks this module as a Phoenix controller for HTTP actions.
@:controller
class GithubOAuthController {
	static function signInWithGithubIdentity(conn:Conn<{}>, identity:GithubIdentity):Conn<{}> {
		var loginResult = Accounts.getOrCreateUserForLogin(identity.email, identity.name);
		return switch (loginResult) {
			case Ok(userRecord):
				conn.putSession("user_id", userRecord.id).putFlash("info", 'Signed in with GitHub as ${userRecord.name}.').redirect("/todos");
			case Error(_):
				{
					conn.putFlash("error", "Could not sign in with GitHub. Please try again.").redirect("/login");
				}
		};
	}

	public static function github(conn:Conn<{}>, params:Term):Conn<{}> {
		if (!GithubOAuth.isConfigured()) {
			return conn.putFlash("error", "GitHub OAuth is not configured. Set GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET.").redirect("/login");
		}

		var state = CSRFProtection.get_csrf_token();
		var withState = conn.putSession("github_oauth_state", state);

		return switch (GithubOAuth.buildAuthorizeUrl(withState, state)) {
			case Ok(url):
				withState.redirectExternal(url);
			case Error(_):
				{
					withState.putFlash("error", "Could not start GitHub login. Please try again.").redirect("/login");
				}
		};
	}

	public static function github_callback(conn:Conn<{}>, params:Term):Conn<{}> {
		var error = Params.getString(params, "error");
		if (error != null) {
			var msg = Params.getStringDefault(params, "error_description", error);
			return conn.putFlash("error", "GitHub login failed: " + msg).redirect("/login");
		}

		var code = Params.getStringDefault(params, "code", "");
		var state = Params.getStringDefault(params, "state", "");

		var storedStateTerm:Term = conn.getSession("github_oauth_state");
		var storedState = Params.stringFromTermDefault(storedStateTerm, "");

		var cleaned = conn.deleteSession("github_oauth_state");
		if (storedState == "" || state == "" || storedState != state) {
			return cleaned.putFlash("error", "GitHub login failed: invalid state. Please try again.").redirect("/login");
		}

		if (code == "") {
			return cleaned.putFlash("error", "GitHub login failed: missing code. Please try again.").redirect("/login");
		}

		return switch (GithubOAuth.authenticate(conn, code)) {
			case Ok(identity):
				signInWithGithubIdentity(cleaned, identity);
			case Error(_):
				{
					cleaned.putFlash("error", "Could not sign in with GitHub. Please try again.").redirect("/login");
				}
		};
	}
}
