package server.services;

import elixir.Application;
import elixir.Atom;
import elixir.ElixirMap;
import elixir.types.Term;
import server.services.MockOAuthIdentity;

using StringTools;

/**
 * MockOAuth
 *
 * WHAT
 * - Deterministic local "OAuth-like" flow for E2E tests and demos.
 *
 * WHY
 * - Real OAuth providers require external secrets and network access, which makes
 *   Playwright and CI runs flaky or non-deterministic. This keeps the showcase
 *   (redirect + callback + state) while staying fully local.
 *
 * HOW
 * - Enabled only when config `:mock_oauth_enabled` is true (intended for MIX_ENV=e2e).
 * - `/auth/mock` stores a CSRF state + identity in the Plug session and redirects to
 *   `/auth/mock/callback?code=mock&state=...`.
 * - The callback validates the state and signs in via `Accounts.getOrCreateUserForLogin/2`.
 */
@:native("TodoApp.MockOAuth")
class MockOAuth {
    public static inline var SESSION_STATE_KEY = "mock_oauth_state";
    public static inline var SESSION_IDENTITY_KEY = "mock_oauth_identity";

    static inline var DEFAULT_EMAIL = "mock-oauth@example.com";
    static inline var DEFAULT_NAME = "Mock OAuth User";

    public static function isEnabled(): Bool {
        var app = Atom.createSafe("todo_app");
        var key = Atom.createSafe("mock_oauth_enabled");
        var enabled: Term = Application.get_env(app, key, false);
        return enabled != null ? cast enabled : false;
    }

    public static function identityFromParams(params: Term): MockOAuthIdentity {
        var emailTerm: Term = params != null ? ElixirMap.get(params, "email") : null;
        var nameTerm: Term = params != null ? ElixirMap.get(params, "name") : null;

        var email: String = emailTerm != null ? cast emailTerm : DEFAULT_EMAIL;
        var name: String = nameTerm != null ? cast nameTerm : DEFAULT_NAME;

        if (email.trim() == "") email = DEFAULT_EMAIL;
        if (name.trim() == "") name = DEFAULT_NAME;

        return {email: email, name: name};
    }

    public static function callbackPath(state: String): String {
        return "/auth/mock/callback?code=mock&state=" + StringTools.urlEncode(state);
    }

    public static function identityToSessionValue(identity: MockOAuthIdentity): Term {
        var map: Term = {};
        map = ElixirMap.put(map, "email", identity.email);
        map = ElixirMap.put(map, "name", identity.name);
        return map;
    }

    public static function identityFromSessionValue(value: Term): Null<MockOAuthIdentity> {
        if (value == null) return null;
        var emailTerm: Term = ElixirMap.get(value, "email");
        var nameTerm: Term = ElixirMap.get(value, "name");
        var email: String = emailTerm != null ? cast emailTerm : "";
        var name: String = nameTerm != null ? cast nameTerm : "";
        if (email.trim() == "" || name.trim() == "") return null;
        return {email: email, name: name};
    }
}

