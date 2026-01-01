package server.live;

import HXX;
import ecto.Changeset;
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
import server.schemas.Organization;
import server.schemas.User;
import server.support.OrganizationTools;
import server.types.Types.MountParams;
import server.types.Types.Session;
import StringTools;
using reflaxe.elixir.macros.TypedQueryLambda;

typedef OrgRowView = {
    var id: Int;
    var slug: String;
    var name: String;
    var is_current: Bool;
}

typedef OrganizationLiveAssigns = {
    var signed_in: Bool;
    var current_user: Null<User>;

    var current_org_id: Int;
    var current_org_slug: String;
    var current_org_name: String;

    var slug_input: String;
    var org_rows: Array<OrgRowView>;
}

typedef OrganizationLiveRenderAssigns = {> OrganizationLiveAssigns,
    var flash: FlashMap;
    var flash_info: Null<String>;
    var flash_error: Null<String>;
}

/**
 * OrganizationLive
 *
 * WHAT
 * - Simple tenant/organization switcher page for the todo-app showcase.
 *
 * WHY
 * - The todo-app is multi-tenant (queries, PubSub, Presence) via `organization_id`.
 *   Exposing the active organization makes the multi-tenant behavior visible and testable.
 *
 * HOW
 * - Signed-in users can switch organizations by slug.
 * - If the organization doesn't exist, it's created.
 * - Switching updates `users.organization_id` (and demo role) then redirects back to `/todos`.
 */
@:native("TodoAppWeb.OrganizationLive")
@:liveview
class OrganizationLive {
    @:keep private static var __keep_fns:Array<Function> = [
        index,
        sessionUserId,
        normalizeSlug,
        loadOrganizations,
        getOrganizationBySlug,
        getOrCreateOrganizationBySlug,
        switchOrganization
    ];

    public static function mount(_params: MountParams, session: Session, socket: Socket<OrganizationLiveAssigns>): MountResult<OrganizationLiveAssigns> {
        var sock: LiveSocket<OrganizationLiveAssigns> = socket;

        var userId = sessionUserId(session);
        var user: Null<User> = userId != null ? Repo.get(User, userId) : null;
        if (userId != null && user == null) {
            sock = LiveView.putFlash(sock, FlashType.Error, "Your session is invalid. Please sign in again.");
            sock = LiveView.pushNavigate(sock, {to: "/login"});
        }

        var signedIn = user != null;
        if (!signedIn || user == null) {
            sock = LiveView.putFlash(sock, FlashType.Error, "Sign in to manage organizations.");
            sock = LiveView.pushNavigate(sock, {to: "/login"});
        }

        var orgInfo = signedIn ? OrganizationTools.infoForId(user.organizationId) : OrganizationTools.infoForId(OrganizationTools.DEMO_ORG_ID);
        var rows = signedIn ? loadOrganizations(orgInfo.id) : [];

        sock = sock.merge({
            signed_in: signedIn,
            current_user: user,
            current_org_id: orgInfo.id,
            current_org_slug: orgInfo.slug,
            current_org_name: orgInfo.name,
            slug_input: orgInfo.slug,
            org_rows: rows
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

    static function normalizeSlug(raw: String): String {
        return StringTools.trim(raw).toLowerCase();
    }

    static function loadOrganizations(currentOrgId: Int): Array<OrgRowView> {
        var query = ecto.TypedQuery.from(Organization);
        var orgs: Array<Organization> = Repo.all(query);
        orgs.sort((a, b) -> a.id - b.id);
        return orgs.map(org -> {
            id: org.id,
            slug: org.slug,
            name: org.name,
            is_current: org.id == currentOrgId
        });
    }

    static function getOrganizationBySlug(slug: String): Null<Organization> {
        var query = ecto.TypedQuery.from(Organization).where(o -> o.slug == slug);
        var orgs: Array<Organization> = Repo.all(query);
        return elixir.Enum.at(orgs, 0);
    }

    static function getOrCreateOrganizationBySlug(slug: String): Result<Organization, Changeset<Organization, server.schemas.Organization.OrganizationParams>> {
        var existing = getOrganizationBySlug(slug);
        if (existing != null) return Ok(existing);

        var data: Organization = cast Kernel.struct(Organization);
        var params: server.schemas.Organization.OrganizationParams = {slug: slug, name: slug};
        var changeset = Organization.changeset(data, params);
        return Repo.insert(changeset);
    }

    public static function handle_event(event: String, params: Term, socket: Socket<OrganizationLiveAssigns>): HandleEventResult<OrganizationLiveAssigns> {
        var sock: LiveSocket<OrganizationLiveAssigns> = socket;
        return switch (event) {
            case "switch_org":
                NoReply(switchOrganization(params, sock));
            case _:
                NoReply(sock);
        };
    }

    @:keep
    static function switchOrganization(params: Term, socket: LiveSocket<OrganizationLiveAssigns>): LiveSocket<OrganizationLiveAssigns> {
        if (!socket.assigns.signed_in || socket.assigns.current_user == null) {
            return LiveView.putFlash(socket, FlashType.Error, "Sign in to switch organizations.");
        }

        var slugTerm: Term = ElixirMap.get(params, "slug");
        var raw: String = slugTerm != null ? cast slugTerm : "";
        var slug = normalizeSlug(raw);
        if (slug == "") {
            return LiveView.putFlash(socket, FlashType.Error, "Organization slug is required.");
        }

        var currentUser: User = socket.assigns.current_user;

        return switch (getOrCreateOrganizationBySlug(slug)) {
            case Error(changeset):
                {
                    Std.string(changeset);
                    LiveView.putFlash(socket, FlashType.Error, "Could not create organization.");
                }
            case Ok(org):
                if (currentUser.organizationId == org.id) {
                    LiveView.putFlash(socket, FlashType.Info, 'Already in organization "${org.slug}".');
                } else {
                    var isFirstUserInOrg = Repo.all(ecto.TypedQuery.from(User).where(u -> u.organizationId == org.id)).length == 0;
                    var role = isFirstUserInOrg ? "admin" : "user";

                    var changeset = Changeset.change(currentUser, {});
                    changeset = changeset.putChange("organization_id", org.id);
                    changeset = changeset.putChange("role", role);

                    switch (Repo.update(changeset)) {
                        case Ok(_updated):
                            var withFlash = LiveView.putFlash(socket, FlashType.Info, 'Switched to organization "${org.slug}".');
                            LiveView.pushNavigate(withFlash, {to: "/todos"});
                        case Error(updateChangeset):
                            {
                                Std.string(updateChangeset);
                                LiveView.putFlash(socket, FlashType.Error, "Could not switch organization.");
                            }
                    }
                }
        };
    }

    @:keep
    public static function render(assigns: OrganizationLiveRenderAssigns): String {
        var renderAssigns: Assigns<OrganizationLiveRenderAssigns> = assigns;
        renderAssigns = Component.assign(renderAssigns, "flash_info", PhoenixFlash.get(assigns.flash, "info"));
        renderAssigns = Component.assign(renderAssigns, "flash_error", PhoenixFlash.get(assigns.flash, "error"));
        assigns = renderAssigns;

        return HXX.hxx('
            <div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-blue-900">
                <div class="container mx-auto px-4 py-10 max-w-3xl">
                    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-8">
                        <div class="flex items-start justify-between gap-4 mb-6">
                            <div>
                                <h1 data-testid="org-title" class="text-3xl font-bold text-gray-900 dark:text-white">Organization</h1>
                                <p class="text-gray-600 dark:text-gray-300">Switch the active tenant for this session.</p>
                            </div>
                            <a data-testid="org-back" href="/todos" class="text-blue-700 dark:text-blue-300 hover:underline">Back to todos</a>
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

                        <if {!@signed_in}>
                            <div class="border border-gray-200 dark:border-gray-700 rounded-lg p-6">
                                <div class="font-semibold text-gray-900 dark:text-white mb-2">Not signed in</div>
                                <p class="text-gray-600 dark:text-gray-300">
                                    Sign in to manage organizations.
                                </p>
                                <div class="mt-4">
                                    <a href="/login" class="text-blue-700 dark:text-blue-300 hover:underline">Go to sign in</a>
                                </div>
                            </div>
                        </if>

                        <if {@signed_in}>
                            <div class="rounded-lg border border-gray-200 dark:border-gray-700 p-6">
                                <div class="text-sm text-gray-600 dark:text-gray-300">
                                    Current org:
                                    <span data-testid="org-current-slug" class="font-semibold text-gray-900 dark:text-white">#{@current_org_slug}</span>
                                </div>

                                <form phx-submit="switch_org" class="mt-4 flex flex-col sm:flex-row gap-3">
                                    <input data-testid="org-input-slug"
                                        type="text"
                                        name="slug"
                                        value={@slug_input}
                                        placeholder="org slug (e.g. demo)"
                                        class="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white"/>
                                    <button data-testid="btn-switch-org"
                                        type="submit"
                                        class="px-5 py-2.5 bg-gradient-to-r from-blue-500 to-indigo-600 text-white font-medium rounded-lg hover:from-blue-600 hover:to-indigo-700 transition-all duration-200 shadow-md">
                                        Switch
                                    </button>
                                </form>

                                <div class="mt-6">
                                    <div class="font-semibold text-gray-900 dark:text-white mb-2">Known organizations</div>
                                    <div class="space-y-2">
                                        <for {o in @org_rows}>
                                            <div class="flex items-center justify-between gap-4 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
                                                <div class="min-w-0">
                                                    <div class="font-medium text-gray-900 dark:text-white truncate">#{o.slug}</div>
                                                    <div class="text-sm text-gray-600 dark:text-gray-300 truncate">#{o.name}</div>
                                                </div>
                                                <if {o.is_current}>
                                                    <span data-testid="org-current-badge" class="shrink-0 inline-flex items-center rounded-full bg-green-100 dark:bg-green-900/30 px-3 py-1 text-xs font-semibold text-green-800 dark:text-green-200">
                                                        Current
                                                    </span>
                                                </if>
                                                <if {!o.is_current}>
                                                    <button data-testid="btn-org-row-switch"
                                                        type="button"
                                                        phx-click="switch_org"
                                                        phx-value-slug={o.slug}
                                                        class="shrink-0 px-4 py-2 bg-gray-100 text-gray-800 rounded-lg hover:bg-gray-200 dark:bg-gray-700 dark:text-white dark:hover:bg-gray-600">
                                                        Switch
                                                    </button>
                                                </if>
                                            </div>
                                        </for>
                                    </div>
                                </div>
                            </div>
                        </if>
                    </div>
                </div>
            </div>
        ');
    }
}

