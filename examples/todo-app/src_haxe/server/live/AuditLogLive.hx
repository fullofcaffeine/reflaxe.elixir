package server.live;

import HXX;
import ecto.TypedQuery;
import ecto.TypedQuery.SortDirection;
import elixir.Atom;
import elixir.ElixirMap;
import elixir.types.Term;
import haxe.Constraints.Function;
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
import server.schemas.AuditLog;
import server.schemas.User;
import server.support.OrganizationTools;
import server.types.Types.MountParams;
import server.types.Types.Session;
import shared.liveview.EventName;
import StringTools;
using reflaxe.elixir.macros.TypedQueryLambda;

typedef AuditLogRowView = {
    var id: String;
    var inserted_at_label: String;
    var actor_id: String;
    var action: String;
    var entity: String;
    var entity_id: String;
    var metadata_label: String;
}

typedef AuditLogLiveAssigns = {
    var signed_in: Bool;
    var is_admin: Bool;
    var current_user: Null<User>;
    // Tenant/organization metadata (zero-logic HXX)
    var organization_slug: String;
    var organization_name: String;

    var action_filter: String;
    var entity_filter: String;
    var actor_id_filter: String;
    var limit_filter: String;

    var audit_rows: Array<AuditLogRowView>;
    var audit_count: Int;
}

typedef AuditLogLiveRenderAssigns = {> AuditLogLiveAssigns,
    var flash: FlashMap;
    var flash_info: Null<String>;
    var flash_error: Null<String>;
}

/**
 * AuditLogLive
 *
 * WHAT
 * - Admin-only page to browse recent audit log entries.
 *
 * WHY
 * - Showcases a realistic Phoenix/Ecto feature authored in Haxe:
 *   - typed inserts + queries (contexts.AuditLogs)
 *   - RBAC guard for LiveView routes
 *   - simple filtering UX that stays "zero-logic" inside HXX
 *
 * HOW
 * - On mount, enforce admin access and load the most recent audit entries for the current org.
 * - Filter form uses `phx-change` to reload rows by action/entity/actor_id.
 */
@:native("TodoAppWeb.AuditLogLive")
@:liveview
class AuditLogLive {
    static inline var DEFAULT_LIMIT = 50;

    @:keep private static var __keep_fns:Array<Function> = [
        index,
        sessionUserId,
        parseOptionalInt,
        parseLimit,
        loadRowsForOrg,
        applyFilters
    ];

    public static function mount(_params: MountParams, session: Session, socket: Socket<AuditLogLiveAssigns>): MountResult<AuditLogLiveAssigns> {
        var sock: LiveSocket<AuditLogLiveAssigns> = socket;

        var userId = sessionUserId(session);
        var currentUser: Null<User> = userId != null ? Repo.get(User, userId) : null;

        if (userId != null && currentUser == null) {
            sock = LiveView.putFlash(sock, FlashType.Error, "Your session is invalid. Please sign in again.");
            sock = LiveView.pushNavigate(sock, {to: "/login"});
        }

        if (currentUser == null) {
            sock = LiveView.putFlash(sock, FlashType.Error, "Sign in to access the audit log.");
            sock = LiveView.pushNavigate(sock, {to: "/login"});
        } else if (currentUser.role != "admin") {
            sock = LiveView.putFlash(sock, FlashType.Error, "Admins only.");
            sock = LiveView.pushNavigate(sock, {to: "/todos"});
        }

        var signedIn = currentUser != null;
        var isAdmin = signedIn && currentUser.role == "admin";
        var orgInfo = signedIn ? OrganizationTools.infoForId(currentUser.organizationId) : OrganizationTools.infoForId(OrganizationTools.DEMO_ORG_ID);

        var actionFilter = "all";
        var entityFilter = "all";
        var actorIdFilter = "";
        var limitFilter = "50";
        var rows = isAdmin ? loadRowsForOrg(currentUser.organizationId, actionFilter, entityFilter, null, parseLimit(limitFilter)) : [];

        sock = sock.merge({
            signed_in: signedIn,
            is_admin: isAdmin,
            current_user: currentUser,
            organization_slug: orgInfo.slug,
            organization_name: orgInfo.name,
            action_filter: actionFilter,
            entity_filter: entityFilter,
            actor_id_filter: actorIdFilter,
            limit_filter: limitFilter,
            audit_rows: rows,
            audit_count: rows.length
        });

        return Ok(sock);
    }

    /**
     * Router action handler (placeholder to satisfy route validation).
     */
    public static function index(): String {
        return "index";
    }

    @:keep
    static function sessionUserId(session: Session): Null<Int> {
        if (session == null) return null;
        var sessionTerm: Term = cast session;
        var primary: Term = ElixirMap.get(sessionTerm, "user_id");
        var chosen: Term = primary != null ? primary : ElixirMap.get(sessionTerm, "userId");
        return chosen != null ? cast chosen : null;
    }

    public static function handle_event(event: String, params: Term, socket: Socket<AuditLogLiveAssigns>): HandleEventResult<AuditLogLiveAssigns> {
        var sock: LiveSocket<AuditLogLiveAssigns> = socket;
        return switch (event) {
            case EventName.FilterAudit:
                NoReply(applyFilters(params, sock));
            case _:
                NoReply(sock);
        };
    }

    static function parseOptionalInt(value: Term): Null<Int> {
        if (value == null) return null;
        if (elixir.Kernel.isInteger(value)) return cast value;
        if (elixir.Kernel.isFloat(value)) return elixir.Kernel.trunc(value);
        if (elixir.Kernel.isBinary(value)) return Std.parseInt(cast value);
        return null;
    }

    static function parseLimit(rawLimit: String): Int {
        var parsed = Std.parseInt(rawLimit);
        if (parsed != null && parsed > 0) return parsed;
        return DEFAULT_LIMIT;
    }

    static function loadRowsForOrg(
        organizationId: Int,
        actionFilter: String,
        entityFilter: String,
        actorId: Null<Int>,
        limit: Int
    ): Array<AuditLogRowView> {
        var baseQuery = TypedQuery.from(AuditLog).where(a -> a.organizationId == organizationId);

        var actorFilteredQuery = (actorId != null && actorId > 0)
            ? baseQuery.where(a -> a.actorId == actorId)
            : baseQuery;

        var normalizedAction = StringTools.trim(actionFilter);
        var actionFilteredQuery = (normalizedAction != "" && normalizedAction != "all")
            ? actorFilteredQuery.where(a -> a.action == normalizedAction)
            : actorFilteredQuery;

        var normalizedEntity = StringTools.trim(entityFilter);
        var entityFilteredQuery = (normalizedEntity != "" && normalizedEntity != "all")
            ? actionFilteredQuery.where(a -> a.entity == normalizedEntity)
            : actionFilteredQuery;

        var finalQuery = entityFilteredQuery.orderBy(a -> [{field: a.id, direction: SortDirection.Desc}]).limit(limit);

        var entries = Repo.all(finalQuery);
        return entries.map(toRowView);
    }

    static function toRowView(entry: AuditLog): AuditLogRowView {
        var insertedAtTerm: Term = ElixirMap.get(cast entry, Atom.create("inserted_at"));
        var insertedAtLabel = insertedAtTerm != null ? Std.string(insertedAtTerm) : "";

        var metadataLabel = entry.metadata != null ? Std.string(entry.metadata) : "";
        var entityIdLabel = entry.entityId != null ? Std.string(entry.entityId) : "";

        return {
            id: Std.string(entry.id),
            inserted_at_label: insertedAtLabel,
            actor_id: Std.string(entry.actorId),
            action: entry.action,
            entity: entry.entity,
            entity_id: entityIdLabel,
            metadata_label: metadataLabel
        };
    }

    @:keep
    static function applyFilters(params: Term, socket: LiveSocket<AuditLogLiveAssigns>): LiveSocket<AuditLogLiveAssigns> {
        if (!socket.assigns.is_admin) return socket;
        if (socket.assigns.current_user == null) return socket;

        var actionTerm: Term = ElixirMap.get(params, "action");
        var entityTerm: Term = ElixirMap.get(params, "entity");
        var actorIdTerm: Term = ElixirMap.get(params, "actor_id");
        var limitTerm: Term = ElixirMap.get(params, "limit");

        var actionFilter = actionTerm != null ? StringTools.trim(cast actionTerm) : socket.assigns.action_filter;
        if (actionFilter == "") actionFilter = "all";

        var entityFilter = entityTerm != null ? StringTools.trim(cast entityTerm) : socket.assigns.entity_filter;
        if (entityFilter == "") entityFilter = "all";

        var actorIdFilter = actorIdTerm != null ? StringTools.trim(cast actorIdTerm) : socket.assigns.actor_id_filter;
        var actorId = StringTools.trim(actorIdFilter) != "" ? Std.parseInt(actorIdFilter) : null;

        var limitFilter = limitTerm != null ? StringTools.trim(cast limitTerm) : socket.assigns.limit_filter;
        if (limitFilter == "") limitFilter = "50";

        var rows = loadRowsForOrg(socket.assigns.current_user.organizationId, actionFilter, entityFilter, actorId, parseLimit(limitFilter));
        return socket.merge({
            action_filter: actionFilter,
            entity_filter: entityFilter,
            actor_id_filter: actorIdFilter,
            limit_filter: limitFilter,
            audit_rows: rows,
            audit_count: rows.length
        });
    }

    @:keep
    public static function render(assigns: AuditLogLiveRenderAssigns): String {
        var renderAssigns: Assigns<AuditLogLiveRenderAssigns> = assigns;
        renderAssigns = Component.assign(renderAssigns, "flash_info", PhoenixFlash.get(assigns.flash, "info"));
        renderAssigns = Component.assign(renderAssigns, "flash_error", PhoenixFlash.get(assigns.flash, "error"));
        assigns = renderAssigns;

        return HXX.hxx('
            <div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-blue-900">
                <div class="container mx-auto px-4 py-10 max-w-6xl">
                    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-8">
                        <div class="flex items-start justify-between gap-4 mb-6">
                            <div>
                                <h1 data-testid="audit-title" class="text-3xl font-bold text-gray-900 dark:text-white">Audit log</h1>
                                <div class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                                    Org: <span data-testid="audit-org-slug">#{@organization_slug}</span>
                                </div>
                                <p class="text-gray-600 dark:text-gray-300">Who did what, and when.</p>
                            </div>
                            <div class="flex items-center gap-3">
                                <a data-testid="audit-back-admin" href="/admin" class="text-blue-700 hover:underline">Back to admin</a>
                                <a href="/todos" class="text-blue-700 hover:underline">Todos</a>
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
                            <div class="flex items-center justify-between gap-4 mb-4">
                                <div class="text-sm text-gray-600 dark:text-gray-300">
                                    Entries: <span data-testid="audit-count" class="font-semibold text-gray-900 dark:text-white">#{@audit_count}</span>
                                </div>
                            </div>

                            <form phx-change=${EventName.FilterAudit} class="flex flex-col md:flex-row gap-3 mb-6">
                                <select data-testid="audit-filter-action" name="action"
                                    class="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                                    <option value="all" selected={@action_filter == "all"}>All actions</option>
                                    <option value="org.invite_created" selected={@action_filter == "org.invite_created"}>Invite created</option>
                                    <option value="user.role_updated" selected={@action_filter == "user.role_updated"}>User role updated</option>
                                </select>

                                <select data-testid="audit-filter-entity" name="entity"
                                    class="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                                    <option value="all" selected={@entity_filter == "all"}>All entities</option>
                                    <option value="organization_invite" selected={@entity_filter == "organization_invite"}>Organization invite</option>
                                    <option value="user" selected={@entity_filter == "user"}>User</option>
                                </select>

                                <input data-testid="audit-filter-actor-id" name="actor_id" type="number" value={@actor_id_filter} placeholder="Actor id…"
                                    phx-debounce="250"
                                    class="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white"/>

                                <select data-testid="audit-filter-limit" name="limit"
                                    class="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                                    <option value="25" selected={@limit_filter == "25"}>25</option>
                                    <option value="50" selected={@limit_filter == "50"}>50</option>
                                    <option value="100" selected={@limit_filter == "100"}>100</option>
                                </select>
                            </form>

                            <div class="overflow-x-auto border border-gray-200 dark:border-gray-700 rounded-lg">
                                <table class="min-w-full text-sm">
                                    <thead class="bg-gray-50 dark:bg-gray-900/20 text-gray-700 dark:text-gray-200">
                                        <tr>
                                            <th class="text-left font-semibold px-4 py-3">At</th>
                                            <th class="text-left font-semibold px-4 py-3">Action</th>
                                            <th class="text-left font-semibold px-4 py-3">Entity</th>
                                            <th class="text-left font-semibold px-4 py-3">Actor</th>
                                            <th class="text-left font-semibold px-4 py-3">Entity id</th>
                                            <th class="text-left font-semibold px-4 py-3">Metadata</th>
                                        </tr>
                                    </thead>
                                    <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
                                        <for {row in @audit_rows}>
                                            <tr data-testid="audit-row" data-id={row.id} class="text-gray-900 dark:text-gray-100">
                                                <td class="px-4 py-3 text-xs text-gray-700 dark:text-gray-200 whitespace-nowrap">#{row.inserted_at_label}</td>
                                                <td class="px-4 py-3 font-medium whitespace-nowrap">#{row.action}</td>
                                                <td class="px-4 py-3 whitespace-nowrap">#{row.entity}</td>
                                                <td class="px-4 py-3 whitespace-nowrap">#{row.actor_id}</td>
                                                <td class="px-4 py-3 whitespace-nowrap">#{row.entity_id}</td>
                                                <td class="px-4 py-3 text-gray-700 dark:text-gray-200">
                                                    <code class="text-xs break-all">#{row.metadata_label}</code>
                                                </td>
                                            </tr>
                                        </for>
                                    </tbody>
                                </table>
                            </div>

                            <if {@audit_count == 0}>
                                <div class="text-center text-gray-600 dark:text-gray-300 mt-6">
                                    No audit entries match your filters.
                                </div>
                            </if>
                        </if>
                    </div>
                </div>
            </div>
        ');
    }
}
