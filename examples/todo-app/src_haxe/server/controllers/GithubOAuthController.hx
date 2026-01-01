package controllers;

import contexts.Accounts;
import elixir.ElixirMap;
import elixir.types.Term;
import haxe.functional.Result;
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
@:native("TodoAppWeb.GithubOAuthController")
@:controller
class GithubOAuthController {
    static function signInWithGithubIdentity(conn: Conn<{}>, identity: GithubIdentity): Conn<{}> {
        var loginResult = Accounts.getOrCreateUserForLogin(identity.email, identity.name);
        return switch (loginResult) {
            case Ok(userRecord):
                conn
                    .putSession("user_id", userRecord.id)
                    .putFlash("info", 'Signed in with GitHub as ${userRecord.name}.')
                    .redirect("/todos");
            case Error(userChangeset):
                {
                    Std.string(userChangeset);
                    conn
                        .putFlash("error", "Could not sign in with GitHub. Please try again.")
                        .redirect("/login");
                }
        };
    }

    public static function github(conn: Conn<{}>, _params: Term): Conn<{}> {
        if (!GithubOAuth.isConfigured()) {
            return conn
                .putFlash("error", "GitHub OAuth is not configured. Set GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET.")
                .redirect("/login");
        }

        var state = CSRFProtection.get_csrf_token();
        var withState = conn.putSession("github_oauth_state", state);

        return switch (GithubOAuth.buildAuthorizeUrl(withState, state)) {
            case Ok(url):
                withState.redirectExternal(url);
            case Error(err):
                {
                    Std.string(err);
                    withState
                        .putFlash("error", "Could not start GitHub login. Please try again.")
                        .redirect("/login");
                }
        };
    }

    public static function github_callback(conn: Conn<{}>, params: Term): Conn<{}> {
        var errorTerm: Term = ElixirMap.get(params, "error");
        if (errorTerm != null) {
            var msgTerm: Term = ElixirMap.get(params, "error_description");
            var msg: String = msgTerm != null ? cast msgTerm : cast errorTerm;
            return conn
                .putFlash("error", "GitHub login failed: " + msg)
                .redirect("/login");
        }

        var codeTerm: Term = ElixirMap.get(params, "code");
        var stateTerm: Term = ElixirMap.get(params, "state");
        var code: String = codeTerm != null ? cast codeTerm : "";
        var state: String = stateTerm != null ? cast stateTerm : "";

        var storedStateTerm: Term = conn.getSession("github_oauth_state");
        var storedState: String = storedStateTerm != null ? cast storedStateTerm : "";

        var cleaned = conn.deleteSession("github_oauth_state");
        if (storedState == "" || state == "" || storedState != state) {
            return cleaned
                .putFlash("error", "GitHub login failed: invalid state. Please try again.")
                .redirect("/login");
        }

        if (code == "") {
            return cleaned
                .putFlash("error", "GitHub login failed: missing code. Please try again.")
                .redirect("/login");
        }

        return switch (GithubOAuth.authenticate(conn, code)) {
            case Ok(identity):
                signInWithGithubIdentity(cleaned, identity);
            case Error(err):
                {
                    Std.string(err);
                    cleaned
                        .putFlash("error", "Could not sign in with GitHub. Please try again.")
                        .redirect("/login");
                }
        };
    }
}
