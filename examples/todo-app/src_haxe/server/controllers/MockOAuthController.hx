package controllers;

import contexts.Accounts;
import elixir.ElixirMap;
import elixir.types.Term;
import haxe.functional.Result;
import plug.Conn;
import plug.CSRFProtection;
import server.services.MockOAuth;

/**
 * MockOAuthController
 *
 * WHAT
 * - Local "OAuth-like" endpoints for deterministic E2E sign-in.
 *
 * WHY
 * - We want Playwright to cover an OAuth-style redirect/callback flow without
 *   requiring external providers or secrets.
 *
 * HOW
 * - `mock/2` stores a state token + identity in the Plug session, then redirects
 *   to our own callback route.
 * - `mock_callback/2` validates state + reads the identity, then signs in using
 *   the same session mechanism as SessionController and GithubOAuthController.
 *
 * SECURITY
 * - Disabled by default. Enable only in e2e via config:
 *   `config :todo_app, :mock_oauth_enabled, true`
 */
@:native("TodoAppWeb.MockOAuthController")
@:controller
class MockOAuthController {
    static function disabled(conn: Conn<{}>): Conn<{}> {
        return conn
            .putFlash("error", "Mock OAuth is disabled.")
            .redirect("/login");
    }

    static function signIn(conn: Conn<{}>, email: String, name: String): Conn<{}> {
        var loginResult = Accounts.getOrCreateUserForLogin(email, name);
        return switch (loginResult) {
            case Ok(userRecord):
                conn
                    .putSession("user_id", userRecord.id)
                    .putFlash("info", 'Signed in with Mock OAuth as ${userRecord.name}.')
                    .redirect("/todos");
            case Error(userChangeset):
                {
                    Std.string(userChangeset);
                    conn
                        .putFlash("error", "Could not sign in. Please try again.")
                        .redirect("/login");
                }
        };
    }

    public static function mock(conn: Conn<{}>, params: Term): Conn<{}> {
        if (!MockOAuth.isEnabled()) return disabled(conn);

        var state = CSRFProtection.get_csrf_token();
        var identity = MockOAuth.identityFromParams(params);

        var withSession = conn
            .putSession(MockOAuth.SESSION_STATE_KEY, state)
            .putSession(MockOAuth.SESSION_IDENTITY_KEY, MockOAuth.identityToSessionValue(identity));

        return withSession.redirect(MockOAuth.callbackPath(state));
    }

    public static function mock_callback(conn: Conn<{}>, params: Term): Conn<{}> {
        if (!MockOAuth.isEnabled()) return disabled(conn);

        var errorTerm: Term = params != null ? ElixirMap.get(params, "error") : null;
        if (errorTerm != null) {
            var msgTerm: Term = ElixirMap.get(params, "error_description");
            var msg: String = msgTerm != null ? cast msgTerm : cast errorTerm;
            return conn
                .putFlash("error", "Mock OAuth failed: " + msg)
                .redirect("/login");
        }

        var codeTerm: Term = params != null ? ElixirMap.get(params, "code") : null;
        var stateTerm: Term = params != null ? ElixirMap.get(params, "state") : null;
        var code: String = codeTerm != null ? cast codeTerm : "";
        var state: String = stateTerm != null ? cast stateTerm : "";

        var storedStateTerm: Term = conn.getSession(MockOAuth.SESSION_STATE_KEY);
        var storedState: String = storedStateTerm != null ? cast storedStateTerm : "";
        var identityTerm: Term = conn.getSession(MockOAuth.SESSION_IDENTITY_KEY);

        var cleaned = conn
            .deleteSession(MockOAuth.SESSION_STATE_KEY)
            .deleteSession(MockOAuth.SESSION_IDENTITY_KEY);

        if (storedState == "" || state == "" || storedState != state) {
            return cleaned
                .putFlash("error", "Mock OAuth failed: invalid state. Please try again.")
                .redirect("/login");
        }

        if (code == "") {
            return cleaned
                .putFlash("error", "Mock OAuth failed: missing code. Please try again.")
                .redirect("/login");
        }

        var identity = MockOAuth.identityFromSessionValue(identityTerm);
        if (identity == null) {
            return cleaned
                .putFlash("error", "Mock OAuth failed: missing identity. Please try again.")
                .redirect("/login");
        }

        return signIn(cleaned, identity.email, identity.name);
    }
}

