package server.services;

import elixir.ElixirMap;
import elixir.HttpClient;
import elixir.Kernel;
import elixir.types.Term;
import haxe.functional.Result;
import server.services.GithubIdentity;

using StringTools;

/**
 * GithubOAuth
 *
 * WHAT
 * - Small, optional GitHub OAuth helper for the todo-app showcase.
 *
 * WHY
 * - Demonstrates third-party auth integration without removing the offline-friendly
 *   demo sign-in flow (email/name).
 *
 * HOW
 * - Reads OAuth config from env:
 *   - `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET`
 *   - Optional `GITHUB_REDIRECT_URI` override (recommended for non-default ports)
 * - Exchanges `code` for an access token, then fetches `/user` and (if needed) `/user/emails`
 *   to resolve a usable email/name.
 */
@:native("TodoApp.GithubOAuth")
class GithubOAuth {
    static inline var AUTHORIZE_URL = "https://github.com/login/oauth/authorize";
    static inline var TOKEN_URL = "https://github.com/login/oauth/access_token";
    static inline var USER_URL = "https://api.github.com/user";
    static inline var EMAILS_URL = "https://api.github.com/user/emails";

    static inline var ENV_CLIENT_ID = "GITHUB_CLIENT_ID";
    static inline var ENV_CLIENT_SECRET = "GITHUB_CLIENT_SECRET";
    static inline var ENV_REDIRECT_URI = "GITHUB_REDIRECT_URI";

    public static function isConfigured(): Bool {
        return Sys.getEnv(ENV_CLIENT_ID) != null && Sys.getEnv(ENV_CLIENT_SECRET) != null;
    }

    public static function defaultRedirectUri(conn: plug.Conn<{}>): String {
        var redirectUriOverride = Sys.getEnv(ENV_REDIRECT_URI);
        if (redirectUriOverride != null && redirectUriOverride.trim() != "") return redirectUriOverride;

        var host: String = cast Reflect.field(conn, "host");
        var port: Int = cast Reflect.field(conn, "port");
        var schemeTerm: Term = cast Reflect.field(conn, "scheme");
        var scheme = schemeTerm != null ? Kernel.toString(schemeTerm) : "http";

        var defaultPort = (scheme == "https") ? 443 : 80;
        var portPart = (port != defaultPort) ? (":" + Std.string(port)) : "";
        return scheme + "://" + host + portPart + "/auth/github/callback";
    }

    public static function buildAuthorizeUrl(conn: plug.Conn<{}>, state: String): Result<String, String> {
        var clientId = Sys.getEnv(ENV_CLIENT_ID);
        if (clientId == null || clientId.trim() == "") return Error("GitHub OAuth is not configured (missing GITHUB_CLIENT_ID).");

        var redirectUri = defaultRedirectUri(conn);
        var query = buildQuery([
            {_0: "client_id", _1: clientId},
            {_0: "redirect_uri", _1: redirectUri},
            {_0: "scope", _1: "user:email"},
            {_0: "state", _1: state}
        ]);

        return Ok(AUTHORIZE_URL + "?" + query);
    }

    public static function authenticate(conn: plug.Conn<{}>, code: String): Result<GithubIdentity, String> {
        var clientId = Sys.getEnv(ENV_CLIENT_ID);
        var clientSecret = Sys.getEnv(ENV_CLIENT_SECRET);
        if (clientId == null || clientId.trim() == "") return Error("GitHub OAuth is not configured (missing GITHUB_CLIENT_ID).");
        if (clientSecret == null || clientSecret.trim() == "") return Error("GitHub OAuth is not configured (missing GITHUB_CLIENT_SECRET).");

        var redirectUri = defaultRedirectUri(conn);

        var body = buildQuery([
            {_0: "client_id", _1: clientId},
            {_0: "client_secret", _1: clientSecret},
            {_0: "code", _1: code},
            {_0: "redirect_uri", _1: redirectUri}
        ]);

        var headers = githubHeaders(null);

        var tokenExchangeResult = HttpClient.postFormJson(TOKEN_URL, body, headers);
        return switch (tokenExchangeResult) {
            case Ok(tokenResp):
                var accessToken = stringField(tokenResp, "access_token");
                if (accessToken == null || accessToken.trim() == "") {
                    return Error("GitHub token exchange failed (missing access_token).");
                }
                resolveIdentity(accessToken);
            case Error(err):
                Error(err);
        };
    }

    static function resolveIdentity(accessToken: String): Result<GithubIdentity, String> {
        var headers = githubHeaders(accessToken);

        var userLookupResult = HttpClient.getJson(USER_URL, headers);
        return switch (userLookupResult) {
            case Ok(user):
                var login = stringField(user, "login");
                if (login == null || login.trim() == "") return Error("GitHub user lookup failed (missing login).");

                var email = stringField(user, "email");
                var name = stringField(user, "name");

                if (email == null || email.trim() == "") {
                    var resolvedEmail = resolvePrimaryEmail(accessToken);
                    var finalEmail = (resolvedEmail != null && resolvedEmail.trim() != "")
                        ? resolvedEmail
                        : (login + "@users.noreply.github.com");

                    var identity: GithubIdentity = {
                        email: finalEmail,
                        name: (name != null && name.trim() != "") ? name : login
                    };
                    return Ok(identity);
                }

                var identity: GithubIdentity = {
                    email: email,
                    name: (name != null && name.trim() != "") ? name : login
                };
                return Ok(identity);
            case Error(err):
                Error(err);
        };
    }

    static function resolvePrimaryEmail(accessToken: String): Null<String> {
        var headers = githubHeaders(accessToken);
        var emailsLookupResult = HttpClient.getJson(EMAILS_URL, headers);
        return switch (emailsLookupResult) {
            case Ok(decoded):
                var emails: Array<Term> = cast decoded;
                if (emails == null || emails.length == 0) return null;
                // Prefer the first returned email for the demo (GitHub generally includes the primary early).
                // If the list is empty or malformed, fall back to nil so caller can use no-reply.
                var first = stringField(emails[0], "email");
                return (first != null && first.trim() != "") ? first : null;
            case Error(err):
                {
                    Std.string(err);
                    null;
                }
        };
    }

    static function githubHeaders(accessToken: Null<String>): Array<{_0: String, _1: String}> {
        var headers: Array<{_0: String, _1: String}> = [
            {_0: "accept", _1: "application/json"},
            {_0: "user-agent", _1: "TodoApp (Reflaxe.Elixir example)"}
        ];

        if (accessToken != null && accessToken.trim() != "") {
            headers.push({_0: "authorization", _1: "Bearer " + accessToken});
        }
        return headers;
    }

    static function stringField(map: Term, key: String): Null<String> {
        if (map == null) return null;
        var value: Term = ElixirMap.get(map, key);
        return value != null ? cast value : null;
    }

    static function buildQuery(pairs: Array<{_0: String, _1: String}>): String {
        var parts: Array<String> = [];
        for (p in pairs) {
            var k = p._0 != null ? p._0 : "";
            var v = p._1 != null ? p._1 : "";
            parts.push(StringTools.urlEncode(k) + "=" + StringTools.urlEncode(v));
        }
        return parts.join("&");
    }
}
