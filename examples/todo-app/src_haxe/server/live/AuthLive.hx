package server.live;

import HXX;
import contexts.Users;
import elixir.ElixirMap;
import elixir.types.Term;
import phoenix.Component;
import phoenix.LiveSocket;
import phoenix.Phoenix.LiveView;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Socket;
import phoenix.PhoenixFlash;
import phoenix.types.Assigns;
import phoenix.types.Flash.FlashMap;
import plug.CSRFProtection;
import shared.liveview.HookName;
import server.services.MockOAuth;
import server.infrastructure.Repo;
import server.types.Types.MountParams;
import server.types.Types.Session;

typedef AuthLiveAssigns = {
    var signed_in: Bool;
    var current_user: Null<server.schemas.User>;
    var users: Array<server.schemas.User>;
    var github_oauth_enabled: Bool;
    var mock_oauth_enabled: Bool;
    var oauth_enabled: Bool;
}

typedef AuthLiveRenderAssigns = {> AuthLiveAssigns,
    var flash: FlashMap;
    var flash_info: Null<String>;
    var flash_error: Null<String>;
}

/**
 * AuthLive
 *
 * WHAT
 * - Demo login page (LiveView) showcasing Plug session integration.
 *
 * WHY
 * - We keep the UI in LiveView/HXX for a consistent dev experience, while the actual
 *   session write happens in a normal controller POST (`/auth/login`) so the Plug
 *   session cookie is updated correctly.
 *
 * HOW
 * - Renders a standard HTML form that POSTs to SessionController.
 * - Lists existing users for quick switching in demos.
 */
@:native("TodoAppWeb.AuthLive")
@:liveview
class AuthLive {
    @:keep private static var __keep_fns:Array<haxe.Constraints.Function> = [
        index,
        sessionUserId
    ];

    public static function mount(_params: MountParams, session: Session, socket: Socket<AuthLiveAssigns>): MountResult<AuthLiveAssigns> {
        var sock: LiveSocket<AuthLiveAssigns> = socket;

        var maybeUserId = sessionUserId(session);
        var signedIn = maybeUserId != null;
        var currentUser: Null<server.schemas.User> = signedIn ? Repo.get(server.schemas.User, cast maybeUserId) : null;
        if (currentUser == null) signedIn = false;

        var users = Users.listUsers(null);
        var githubOAuthEnabled = Sys.getEnv("GITHUB_CLIENT_ID") != null && Sys.getEnv("GITHUB_CLIENT_SECRET") != null;
        var mockOAuthEnabled = MockOAuth.isEnabled();
        sock = sock.merge({
            signed_in: signedIn,
            current_user: currentUser,
            users: users,
            github_oauth_enabled: githubOAuthEnabled,
            mock_oauth_enabled: mockOAuthEnabled,
            oauth_enabled: githubOAuthEnabled || mockOAuthEnabled
        });
        return Ok(sock);
    }

    @:keep
    static function sessionUserId(session: Session): Null<Int> {
        if (session == null) return null;
        var sessionTerm: Term = cast session;
        var primary: Term = ElixirMap.get(sessionTerm, "user_id");
        var chosen: Term = primary != null ? primary : ElixirMap.get(sessionTerm, "userId");
        return chosen != null ? cast chosen : null;
    }

    /**
     * Router action handler (placeholder to satisfy route validation).
     */
    public static function index(): String {
        return "index";
    }

    @:keep
    public static function render(assigns: AuthLiveRenderAssigns): String {
        var renderAssigns: Assigns<AuthLiveRenderAssigns> = assigns;
        renderAssigns = Component.assign(renderAssigns, "flash_info", PhoenixFlash.get(assigns.flash, "info"));
        renderAssigns = Component.assign(renderAssigns, "flash_error", PhoenixFlash.get(assigns.flash, "error"));
        assigns = renderAssigns;

        return HXX.hxx('
            <div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-blue-900">
                <div class="container mx-auto px-4 py-10 max-w-3xl">
                    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-8">
                        <h1 class="text-3xl font-bold text-gray-900 dark:text-white mb-2">Sign in</h1>
                        <p class="text-gray-600 dark:text-gray-300 mb-6">
                            Optional demo login. No passwords — just pick a name + email and we’ll create a user.
                        </p>

                        <if {@flash_info}>
                            <div data-testid="flash-info" class="bg-blue-50 border border-blue-200 text-blue-700 px-4 py-3 rounded-lg mb-4">
                                #{@flash_info}
                            </div>
                        </if>
                        <if {@flash_error}>
                            <div data-testid="flash-error" class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-4">
                                #{@flash_error}
                            </div>
                        </if>

                        <if {@signed_in}>
                            <div class="border border-green-200 bg-green-50 dark:bg-green-900/20 dark:border-green-800 rounded-lg p-4 mb-6">
                                <div class="font-semibold text-green-800 dark:text-green-200">Signed in</div>
                                <div class="text-green-700 dark:text-green-200">
                                    #{@current_user.name} &lt;#{@current_user.email}&gt;
                                </div>
                                <form action="/auth/logout" method="post" class="mt-4">
                                    <input type="hidden" name="_csrf_token" value=${CSRFProtection.get_csrf_token()}/>
                                    <button type="submit" class="px-4 py-2 bg-gray-900 text-white rounded-lg hover:bg-gray-800">
                                        Sign out
                                    </button>
                                    <a href="/todos" class="ml-3 text-blue-700 hover:underline">Back to todos</a>
                                </form>
                            </div>
                        </if>

		                        <div class="grid grid-cols-1 gap-6">
		                            <div class="border border-gray-200 dark:border-gray-700 rounded-lg p-5">
		                                <div class="font-semibold text-gray-800 dark:text-white mb-3">Sign in / create user</div>
		                                <if {@mock_oauth_enabled}>
		                                    <a data-testid="btn-mock-oauth"
		                                        href="/auth/mock"
		                                        class="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg bg-indigo-600 text-white hover:bg-indigo-700 transition-all duration-200 shadow-md mb-4">
		                                        Continue with Mock OAuth (E2E)
		                                    </a>
		                                </if>
		                                <if {@github_oauth_enabled}>
		                                    <a data-testid="btn-github-oauth"
		                                        href="/auth/github"
		                                        class="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg bg-gray-900 text-white hover:bg-gray-800 transition-all duration-200 shadow-md mb-4">
		                                        <span aria-hidden="true">🐙</span>
		                                        Continue with GitHub
		                                    </a>
		                                </if>
		                                <if {@oauth_enabled}>
		                                    <div class="flex items-center gap-3 text-xs text-gray-500 dark:text-gray-400 mb-4">
		                                        <div class="h-px flex-1 bg-gray-200 dark:bg-gray-700"></div>
		                                        <div>or</div>
		                                        <div class="h-px flex-1 bg-gray-200 dark:bg-gray-700"></div>
		                                    </div>
		                                </if>
		                                <if {!@oauth_enabled}>
		                                    <div data-testid="github-oauth-disabled" class="text-xs text-gray-500 dark:text-gray-400 mb-4">
		                                        GitHub OAuth is disabled (set <code>GITHUB_CLIENT_ID</code> and <code>GITHUB_CLIENT_SECRET</code> to enable).
		                                    </div>
		                                </if>
		                                <form action="/auth/login" method="post" class="space-y-4">
	                                    <input type="hidden" name="_csrf_token" value=${CSRFProtection.get_csrf_token()}/>

                                    <div>
                                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-200 mb-1">Name</label>
                                        <input data-testid="login-name"
                                            id="login-name"
                                            name="name"
                                            type="text"
                                            required
                                            minlength="2"
                                            phx-hook=${HookName.AutoFocus}
                                            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white"/>
                                    </div>

                                    <div>
                                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-200 mb-1">Email</label>
                                        <input name="email" type="email" required
                                            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white"/>
                                    </div>

                                    <button type="submit" class="w-full py-2.5 bg-gradient-to-r from-blue-500 to-indigo-600 text-white font-medium rounded-lg hover:from-blue-600 hover:to-indigo-700 transition-all duration-200 shadow-md">
                                        Continue
                                    </button>
                                </form>
                            </div>

                            <div class="border border-gray-200 dark:border-gray-700 rounded-lg p-5">
                                <div class="font-semibold text-gray-800 dark:text-white mb-3">Quick switch</div>
                                <p class="text-sm text-gray-600 dark:text-gray-300 mb-4">
                                    Choose an existing user from the database:
                                </p>
                                <div class="space-y-3">
                                    <for {u in @users}>
                                        <div class="flex items-center justify-between gap-3 p-3 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
                                            <div class="min-w-0">
                                                <div class="font-medium text-gray-900 dark:text-white truncate">#{u.name}</div>
                                                <div class="text-sm text-gray-600 dark:text-gray-300 truncate">#{u.email}</div>
                                            </div>
                                            <form action="/auth/login" method="post" class="shrink-0">
                                                <input type="hidden" name="_csrf_token" value=${CSRFProtection.get_csrf_token()}/>
                                                <input type="hidden" name="name" value={u.name}/>
                                                <input type="hidden" name="email" value={u.email}/>
                                                <button type="submit" class="px-3 py-1.5 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-600">
                                                    Sign in
                                                </button>
                                            </form>
                                        </div>
                                    </for>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        ');
    }
}
