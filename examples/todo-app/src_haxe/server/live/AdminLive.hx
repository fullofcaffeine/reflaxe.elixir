package server.live;

import HXX;
import elixir.ElixirMap;
import elixir.types.Term;
import haxe.Constraints.Function;
import phoenix.Component;
import phoenix.LiveSocket;
import phoenix.Phoenix.LiveView;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Socket;
import phoenix.PhoenixFlash;
import phoenix.types.Assigns;
import phoenix.types.Flash.FlashMap;
import phoenix.types.Flash.FlashType;
import plug.CSRFProtection;
import server.infrastructure.Repo;
import server.schemas.User;
import server.types.Types.MountParams;
import server.types.Types.Session;
import shared.liveview.HookName;

typedef AdminLiveAssigns = {
    var signed_in: Bool;
    var is_admin: Bool;
    var current_user: Null<User>;
    var users: Array<User>;
    var total_users: Int;
    var admin_users: Int;
    var regular_users: Int;
}

typedef AdminLiveRenderAssigns = {> AdminLiveAssigns,
    var flash: FlashMap;
    var flash_info: Null<String>;
    var flash_error: Null<String>;
}

/**
 * AdminLive
 *
 * WHAT
 * - Admin-only dashboard page for the todo-app showcase.
 *
 * WHY
 * - Demonstrates a simple authorization guard (role-based) for LiveView routes.
 *
 * HOW
 * - Reads the signed-in user from the LiveView session and redirects non-admins back to `/todos`.
 * - Loads and summarizes users for a small dashboard view model.
 */
@:native("TodoAppWeb.AdminLive")
@:liveview
class AdminLive {
    @:keep private static var __keep_fns:Array<Function> = [
        index,
        sessionUserId
    ];

    public static function mount(_params: MountParams, session: Session, socket: Socket<AdminLiveAssigns>): MountResult<AdminLiveAssigns> {
        var sock: LiveSocket<AdminLiveAssigns> = socket;

        var userId = sessionUserId(session);
        var currentUser: Null<User> = userId != null ? Repo.get(User, userId) : null;

        if (userId != null && currentUser == null) {
            sock = LiveView.putFlash(sock, FlashType.Error, "Your session is invalid. Please sign in again.");
            sock = LiveView.pushNavigate(sock, {to: "/login"});
        }

        if (currentUser == null) {
            sock = LiveView.putFlash(sock, FlashType.Error, "Sign in to access the admin dashboard.");
            sock = LiveView.pushNavigate(sock, {to: "/login"});
        } else if (currentUser.role != "admin") {
            sock = LiveView.putFlash(sock, FlashType.Error, "Admins only.");
            sock = LiveView.pushNavigate(sock, {to: "/todos"});
        }

        var signedIn = currentUser != null;
        var isAdmin = signedIn && currentUser.role == "admin";

        var users = isAdmin ? loadUsers() : [];
        var stats = deriveRoleStats(users);

        sock = sock.merge({
            signed_in: signedIn,
            is_admin: isAdmin,
            current_user: currentUser,
            users: users,
            total_users: users.length,
            admin_users: stats.admin,
            regular_users: stats.regular
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

    static function loadUsers(): Array<User> {
        var users = Repo.all(ecto.TypedQuery.from(User));
        users.sort((a, b) -> a.id - b.id);
        return users;
    }

    static function deriveRoleStats(users: Array<User>): {admin: Int, regular: Int} {
        var adminCount = 0;
        var regularCount = 0;
        for (user in users) {
            if (user.role == "admin") adminCount++; else regularCount++;
        }
        return {admin: adminCount, regular: regularCount};
    }

    @:keep
    public static function render(assigns: AdminLiveRenderAssigns): String {
        var renderAssigns: Assigns<AdminLiveRenderAssigns> = assigns;
        renderAssigns = Component.assign(renderAssigns, "flash_info", PhoenixFlash.get(assigns.flash, "info"));
        renderAssigns = Component.assign(renderAssigns, "flash_error", PhoenixFlash.get(assigns.flash, "error"));
        assigns = renderAssigns;

        return HXX.hxx('
            <div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-blue-900">
                <div class="container mx-auto px-4 py-10 max-w-4xl">
                    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-8">
                        <div class="flex items-start justify-between gap-4 mb-6">
                            <div>
                                <h1 data-testid="admin-title" class="text-3xl font-bold text-gray-900 dark:text-white">Admin dashboard</h1>
                                <p class="text-gray-600 dark:text-gray-300">Role-based access control showcase.</p>
                            </div>
                            <div class="flex items-center gap-3">
                                <button
                                    data-testid="admin-theme-toggle"
                                    id="admin-theme-toggle"
                                    type="button"
                                    phx-hook=${HookName.ThemeToggle}
                                    aria-label="Toggle theme"
                                    class="inline-flex items-center gap-2 rounded-lg px-3 py-1.5 bg-gray-100 text-gray-800 hover:bg-gray-200 dark:bg-gray-700 dark:text-white dark:hover:bg-gray-600">
                                    <span aria-hidden="true">🌓</span>
                                    <span data-theme-label class="text-xs font-medium">Theme</span>
                                </button>
                                <a href="/todos" class="text-blue-700 hover:underline">Back to todos</a>
                                <if {@signed_in}>
                                    <form action="/auth/logout" method="post" class="inline">
                                        <input type="hidden" name="_csrf_token" value=${CSRFProtection.get_csrf_token()}/>
                                        <button data-testid="admin-sign-out" type="submit" class="text-gray-700 dark:text-gray-200 hover:underline">
                                            Sign out
                                        </button>
                                    </form>
                                </if>
                            </div>
                        </div>

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

                        <if {!@is_admin}>
                            <div class="border border-gray-200 dark:border-gray-700 rounded-lg p-6">
                                <div class="font-semibold text-gray-900 dark:text-white mb-2">Not authorized</div>
                                <p class="text-gray-600 dark:text-gray-300">
                                    You do not have access to this page.
                                </p>
                            </div>
                        </if>

                        <if {@is_admin}>
                            <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                                <div class="rounded-lg border border-gray-200 dark:border-gray-700 p-4">
                                    <div class="text-xs uppercase tracking-wide text-gray-500 dark:text-gray-400">Users</div>
                                    <div data-testid="admin-stat-total-users" class="text-2xl font-bold text-gray-900 dark:text-white">#{@total_users}</div>
                                </div>
                                <div class="rounded-lg border border-gray-200 dark:border-gray-700 p-4">
                                    <div class="text-xs uppercase tracking-wide text-gray-500 dark:text-gray-400">Admins</div>
                                    <div data-testid="admin-stat-admins" class="text-2xl font-bold text-gray-900 dark:text-white">#{@admin_users}</div>
                                </div>
                                <div class="rounded-lg border border-gray-200 dark:border-gray-700 p-4">
                                    <div class="text-xs uppercase tracking-wide text-gray-500 dark:text-gray-400">Regular users</div>
                                    <div data-testid="admin-stat-regular" class="text-2xl font-bold text-gray-900 dark:text-white">#{@regular_users}</div>
                                </div>
                            </div>

                            <div class="mt-8">
                                <div class="font-semibold text-gray-900 dark:text-white mb-3">All users</div>
                                <div class="space-y-2">
                                    <for {u in @users}>
                                        <div data-testid="admin-user-row" class="flex items-center justify-between gap-4 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
                                            <div class="min-w-0">
                                                <div class="font-medium text-gray-900 dark:text-white truncate">#{u.name}</div>
                                                <div class="text-sm text-gray-600 dark:text-gray-300 truncate">#{u.email}</div>
                                            </div>
                                            <div data-testid="admin-user-role" class="shrink-0 inline-flex items-center rounded-full bg-gray-100 dark:bg-gray-700 px-3 py-1 text-xs font-semibold text-gray-800 dark:text-white">
                                                #{u.role}
                                            </div>
                                        </div>
                                    </for>
                                </div>
                            </div>
                        </if>
                    </div>
                </div>
            </div>
        ');
    }
}

