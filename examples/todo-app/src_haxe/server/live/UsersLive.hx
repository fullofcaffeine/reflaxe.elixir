package server.live;

import HXX;
import contexts.Users;
import elixir.ElixirMap;
import elixir.Kernel;
import elixir.types.Term;
import haxe.Constraints.Function;
import haxe.functional.Result;
import phoenix.Component;
import phoenix.LiveSocket;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.LiveView;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Socket;
import phoenix.PhoenixFlash;
import phoenix.types.Assigns;
import phoenix.types.Flash.FlashMap;
import phoenix.types.Flash.FlashType;
import server.infrastructure.Repo;
import server.schemas.User;
import server.types.Types.MountParams;
import server.types.Types.Session;
import shared.AvatarTools;
import StringTools;

typedef UserRowView = {
    var id: Int;
    var name: String;
    var email: String;
    var avatar_initials: String;
    var avatar_class: String;
    var avatar_style: String;
    var status_label: String;
    var status_class: String;
    var last_login_label: String;
    var toggle_label: String;
    var toggle_class: String;
}

typedef UsersLiveAssigns = {
    var signed_in: Bool;
    var current_user: Null<User>;

    var search_query: String;
    var status_filter: String;

    var all_users: Array<User>;
    var visible_users: Array<UserRowView>;

    var total_users: Int;
    var active_users: Int;
    var inactive_users: Int;
}

typedef UsersLiveRenderAssigns = {> UsersLiveAssigns,
    var flash: FlashMap;
    var flash_info: Null<String>;
    var flash_error: Null<String>;
}

/**
 * UsersLive
 *
 * WHAT
 * - User directory / admin-ish page for the todo-app showcase.
 *
 * WHY
 * - Demonstrates typed DB reads and LiveView state updates beyond the Todo CRUD flow:
 *   search, filtering, and a small “toggle active” action.
 *
 * HOW
 * - Loads users from the database, derives stats, and keeps rendering “zero-logic” by
 *   precomputing a row view model (UserRowView) for the template.
 */
@:native("TodoAppWeb.UsersLive")
@:liveview
class UsersLive {
    @:keep private static var __keep_fns:Array<Function> = [
        index,
        sessionUserId,
        applyFilters,
        parseId,
        toggleActive
    ];

    public static function mount(_params: MountParams, session: Session, socket: Socket<UsersLiveAssigns>): MountResult<UsersLiveAssigns> {
        var sock: LiveSocket<UsersLiveAssigns> = socket;

        var maybeUserId = sessionUserId(session);
        var signedIn = maybeUserId != null;
        var currentUser: Null<User> = signedIn ? Repo.get(User, cast maybeUserId) : null;
        if (currentUser == null) signedIn = false;

        var allUsers = loadUsers();
        var stats = deriveStats(allUsers);
        var searchQuery = "";
        var statusFilter = "all";

        sock = sock.merge({
            signed_in: signedIn,
            current_user: currentUser,
            search_query: searchQuery,
            status_filter: statusFilter,
            all_users: allUsers,
            visible_users: buildRows(filterUsers(allUsers, searchQuery, statusFilter)),
            total_users: stats.total,
            active_users: stats.active,
            inactive_users: stats.inactive
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

    public static function handle_event(event: String, params: Term, socket: Socket<UsersLiveAssigns>): HandleEventResult<UsersLiveAssigns> {
        var sock: LiveSocket<UsersLiveAssigns> = socket;

        return switch (event) {
            case "filter_users":
                NoReply(applyFilters(params, sock));
            case "toggle_active":
                NoReply(toggleActive(params, sock));
            case _:
                NoReply(sock);
        };
    }

    @:keep
    static function applyFilters(params: Term, socket: LiveSocket<UsersLiveAssigns>): LiveSocket<UsersLiveAssigns> {
        var queryTerm: Term = ElixirMap.get(params, "query");
        var statusTerm: Term = ElixirMap.get(params, "status");

        var searchQuery = queryTerm != null ? StringTools.trim(cast queryTerm) : socket.assigns.search_query;
        var statusFilter = statusTerm != null ? cast statusTerm : socket.assigns.status_filter;
        if (statusFilter != "all" && statusFilter != "active" && statusFilter != "inactive") statusFilter = "all";

        var visible = buildRows(filterUsers(socket.assigns.all_users, searchQuery, statusFilter));
        return socket.merge({
            search_query: searchQuery,
            status_filter: statusFilter,
            visible_users: visible
        });
    }

    @:keep
    static function toggleActive(params: Term, socket: LiveSocket<UsersLiveAssigns>): LiveSocket<UsersLiveAssigns> {
        if (!socket.assigns.signed_in) {
            return LiveView.putFlash(socket, FlashType.Error, "Sign in to manage users.");
        }

        var idValue = parseId(ElixirMap.get(params, "id"));
        if (idValue == null) {
            return LiveView.putFlash(socket, FlashType.Error, "Invalid user id.");
        }

        var user = Users.getUserSafe(idValue);
        if (user == null) {
            return LiveView.putFlash(socket, FlashType.Error, "User not found.");
        }

        return switch (Users.updateUser(user, {active: !user.active})) {
            case Ok(updated):
                var allUsers = loadUsers();
                var stats = deriveStats(allUsers);
                var visible = buildRows(filterUsers(allUsers, socket.assigns.search_query, socket.assigns.status_filter));
                var updatedSocket = socket.merge({
                    all_users: allUsers,
                    visible_users: visible,
                    total_users: stats.total,
                    active_users: stats.active,
                    inactive_users: stats.inactive
                });
                LiveView.putFlash(updatedSocket, FlashType.Info, updated.active ? "User activated." : "User deactivated.");

            case Error(_changeset):
                LiveView.putFlash(socket, FlashType.Error, "Could not update user.");
        };
    }

    @:keep
    static function parseId(value: Term): Null<Int> {
        if (value == null) return null;
        if (Kernel.isInteger(value)) return cast value;
        if (Kernel.isFloat(value)) return Kernel.trunc(value);
        if (Kernel.isBinary(value)) return Std.parseInt(cast value);
        return null;
    }

    static function loadUsers(): Array<User> {
        var users = Users.listUsers(null);
        // Stable ordering improves UX and test determinism.
        users.sort(function(a, b) return a.id - b.id);
        return users;
    }

    static function deriveStats(users: Array<User>): contexts.Users.UserStats {
        var total = users.length;
        var active = 0;
        for (user in users) {
            if (user.active) active++;
        }
        return {total: total, active: active, inactive: total - active};
    }

    static function filterUsers(users: Array<User>, searchQuery: String, statusFilter: String): Array<User> {
        var filtered = users;

        var query = StringTools.trim(searchQuery).toLowerCase();
        if (query != "") {
            filtered = filtered.filter(user -> {
                var name = user.name != null ? user.name.toLowerCase() : "";
                var email = user.email != null ? user.email.toLowerCase() : "";
                return StringTools.contains(name, query) || StringTools.contains(email, query);
            });
        }

        if (statusFilter == "active") {
            filtered = filtered.filter(user -> user.active);
        } else if (statusFilter == "inactive") {
            filtered = filtered.filter(user -> !user.active);
        }

        return filtered;
    }

    static function buildRows(users: Array<User>): Array<UserRowView> {
        return users.map(toRowView);
    }

    static function toRowView(user: User): UserRowView {
        var avatarInitials = AvatarTools.initials(user.name, user.email);
        var avatarBgClass = AvatarTools.avatarBgClass(user.name, user.email);
        var avatarStyle = AvatarTools.avatarStyle(user.name, user.email, 64);
        var avatarClass = "h-9 w-9 rounded-full flex items-center justify-center text-white font-semibold shadow-sm bg-cover bg-center " + avatarBgClass;

        var statusLabel = user.active ? "Active" : "Inactive";
        var statusClass = user.active
            ? "inline-flex items-center px-2 py-1 rounded bg-green-50 text-green-700 border border-green-200 text-xs dark:bg-green-900/30 dark:text-green-200 dark:border-green-800"
            : "inline-flex items-center px-2 py-1 rounded bg-gray-50 text-gray-700 border border-gray-200 text-xs dark:bg-gray-800 dark:text-gray-200 dark:border-gray-700";

        var lastLoginLabel = user.lastLoginAt != null ? Std.string(user.lastLoginAt) : "Never";

        var toggleLabel = user.active ? "Deactivate" : "Activate";
        var toggleClass = user.active
            ? "px-3 py-1.5 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-600 text-sm"
            : "px-3 py-1.5 bg-gray-900 text-white rounded-lg hover:bg-gray-800 text-sm";

        return {
            id: user.id,
            name: user.name,
            email: user.email,
            avatar_initials: avatarInitials,
            avatar_class: avatarClass,
            avatar_style: avatarStyle,
            status_label: statusLabel,
            status_class: statusClass,
            last_login_label: lastLoginLabel,
            toggle_label: toggleLabel,
            toggle_class: toggleClass
        };
    }

    @:keep
    public static function render(assigns: UsersLiveRenderAssigns): String {
        var renderAssigns: Assigns<UsersLiveRenderAssigns> = assigns;
        renderAssigns = Component.assign(renderAssigns, "flash_info", PhoenixFlash.get(assigns.flash, "info"));
        renderAssigns = Component.assign(renderAssigns, "flash_error", PhoenixFlash.get(assigns.flash, "error"));
        assigns = renderAssigns;

        return HXX.hxx('
            <div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-blue-900">
                <div class="container mx-auto px-4 py-10 max-w-5xl">
                    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-8">
                        <div class="flex items-start justify-between gap-4 mb-6">
                            <div>
                                <h1 class="text-3xl font-bold text-gray-900 dark:text-white">Users</h1>
                                <p class="text-gray-600 dark:text-gray-300">
                                    Directory + search for the optional login showcase.
                                </p>
                            </div>
                            <a href="/todos" class="text-blue-700 hover:underline">Back to todos</a>
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

                        <div class="grid grid-cols-3 gap-4 mb-6">
                            <div class="bg-gray-50 dark:bg-gray-900/20 border border-gray-200 dark:border-gray-700 rounded-lg p-4">
                                <div class="text-sm text-gray-600 dark:text-gray-300">Total</div>
                                <div data-testid="users-total" class="text-2xl font-bold text-gray-900 dark:text-white">#{@total_users}</div>
                            </div>
                            <div class="bg-gray-50 dark:bg-gray-900/20 border border-gray-200 dark:border-gray-700 rounded-lg p-4">
                                <div class="text-sm text-gray-600 dark:text-gray-300">Active</div>
                                <div data-testid="users-active" class="text-2xl font-bold text-green-700 dark:text-green-200">#{@active_users}</div>
                            </div>
                            <div class="bg-gray-50 dark:bg-gray-900/20 border border-gray-200 dark:border-gray-700 rounded-lg p-4">
                                <div class="text-sm text-gray-600 dark:text-gray-300">Inactive</div>
                                <div data-testid="users-inactive" class="text-2xl font-bold text-gray-700 dark:text-gray-200">#{@inactive_users}</div>
                            </div>
                        </div>

                        <form phx-change="filter_users" class="flex flex-col md:flex-row gap-3 mb-6">
                            <input data-testid="users-search" name="query" type="text" value={@search_query} placeholder="Search name or email…"
                                phx-debounce="250"
                                class="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white"/>

                            <select data-testid="users-status" name="status"
                                class="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                                <option value="all" selected={@status_filter == "all"}>All statuses</option>
                                <option value="active" selected={@status_filter == "active"}>Active</option>
                                <option value="inactive" selected={@status_filter == "inactive"}>Inactive</option>
                            </select>
                        </form>

                        <if {!@signed_in}>
                            <div class="border border-gray-200 dark:border-gray-700 rounded-lg p-5 mb-6">
                                <div class="font-semibold text-gray-900 dark:text-white mb-1">Demo mode</div>
                                <p class="text-gray-600 dark:text-gray-300">
                                    Sign in to toggle active status.
                                    <a class="text-blue-700 hover:underline" href="/login">Go to sign in</a>
                                </p>
                            </div>
                        </if>

                        <div class="overflow-x-auto border border-gray-200 dark:border-gray-700 rounded-lg">
                            <table class="min-w-full text-sm">
                                <thead class="bg-gray-50 dark:bg-gray-900/20 text-gray-700 dark:text-gray-200">
                                    <tr>
                                        <th class="text-left font-semibold px-4 py-3">Name</th>
                                        <th class="text-left font-semibold px-4 py-3">Email</th>
                                        <th class="text-left font-semibold px-4 py-3">Status</th>
                                        <th class="text-left font-semibold px-4 py-3">Last login</th>
                                        <th class="text-right font-semibold px-4 py-3">Actions</th>
                                    </tr>
                                </thead>
                                <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
                                    <for {u in @visible_users}>
                                        <tr data-testid="users-row" data-id={u.id} class="text-gray-900 dark:text-gray-100">
                                            <td class="px-4 py-3">
                                                <div class="flex items-center gap-3">
                                                    <div data-testid="user-avatar"
                                                        class={u.avatar_class}
                                                        style={u.avatar_style}>
                                                        #{u.avatar_initials}
                                                    </div>
                                                    <span class="font-medium">#{u.name}</span>
                                                </div>
                                            </td>
                                            <td class="px-4 py-3 text-gray-700 dark:text-gray-200">#{u.email}</td>
                                            <td class="px-4 py-3">
                                                <span class={u.status_class}>#{u.status_label}</span>
                                            </td>
                                            <td class="px-4 py-3 text-gray-700 dark:text-gray-200">#{u.last_login_label}</td>
                                            <td class="px-4 py-3 text-right">
                                                <button type="button" phx-click="toggle_active" phx-value-id={u.id} data-testid="users-toggle-active"
                                                    class={u.toggle_class}>
                                                    #{u.toggle_label}
                                                </button>
                                            </td>
                                        </tr>
                                    </for>
                                </tbody>
                            </table>
                        </div>

                        <if {@visible_users.length == 0}>
                            <div class="text-center text-gray-600 dark:text-gray-300 mt-6">
                                No users match your filters.
                            </div>
                        </if>
                    </div>
                </div>
            </div>
        ');
    }
}
