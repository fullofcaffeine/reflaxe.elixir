package server.live;

import HXX;
import elixir.ElixirMap;
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
import plug.CSRFProtection;
import server.infrastructure.Repo;
import server.types.Types.EventParams;
import server.types.Types.MountParams;
import server.types.Types.Session;
import StringTools;

typedef ProfileLiveAssigns = {
    var signed_in: Bool;
    var user: Null<server.schemas.User>;
    var name: String;
    var email: String;
}

typedef ProfileLiveRenderAssigns = {> ProfileLiveAssigns,
    var flash: FlashMap;
    var flash_info: Null<String>;
    var flash_error: Null<String>;
}

/**
 * ProfileLive
 *
 * WHAT
 * - Profile page for the optional login showcase.
 *
 * WHY
 * - Demonstrates a DB-backed edit form (Ecto changeset + Repo.update) authored in Haxe,
 *   rendered with HXX, and wired through Phoenix LiveView events.
 *
 * HOW
 * - Reads `user_id` from the LiveView session (provided by TodoAppWeb.live_session/1).
 * - Loads the user schema and allows editing name/email.
 */
@:native("TodoAppWeb.ProfileLive")
@:liveview
class ProfileLive {
    @:keep private static var __keep_fns:Array<Function> = [
        show,
        sessionUserId,
        saveProfile
    ];

    public static function mount(_params: MountParams, session: Session, socket: Socket<ProfileLiveAssigns>): MountResult<ProfileLiveAssigns> {
        var sock: LiveSocket<ProfileLiveAssigns> = socket;

        var userId = sessionUserId(session);
        var user: Null<server.schemas.User> = userId != null ? Repo.get(server.schemas.User, userId) : null;
        if (userId != null && user == null) {
            sock = LiveView.putFlash(sock, FlashType.Error, "Your session is invalid. Please sign in again.");
            sock = LiveView.pushNavigate(sock, {to: "/login"});
        }

        var signedIn = user != null;
        sock = sock.merge({
            signed_in: signedIn,
            user: user,
            name: signedIn ? user.name : "",
            email: signedIn ? user.email : ""
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
    public static function show(): String {
        return "show";
    }

    public static function handle_event(event: String, params: EventParams, socket: Socket<ProfileLiveAssigns>): HandleEventResult<ProfileLiveAssigns> {
        var sock: LiveSocket<ProfileLiveAssigns> = socket;
        return switch (event) {
            case "save_profile":
                NoReply(saveProfile(params, sock));
            case _:
                NoReply(sock);
        };
    }

    @:keep
    static function saveProfile(params: EventParams, socket: LiveSocket<ProfileLiveAssigns>): LiveSocket<ProfileLiveAssigns> {
        if (!socket.assigns.signed_in || socket.assigns.user == null) {
            return LiveView.putFlash(socket, FlashType.Error, "You must sign in to update your profile.");
        }

        var paramsTerm: Term = cast params;
        var nameTerm: Term = ElixirMap.get(paramsTerm, "name");
        var emailTerm: Term = ElixirMap.get(paramsTerm, "email");

        var name = nameTerm != null ? StringTools.trim(cast nameTerm) : "";
        var email = emailTerm != null ? StringTools.trim(cast emailTerm) : "";
        var updateParams: Term = {name: name, email: email};

        var user: server.schemas.User = socket.assigns.user;
        var changeset = server.schemas.User.changeset(user, updateParams);

        return switch (Repo.update(changeset)) {
            case Ok(updated):
                var updatedSocket = socket.merge({
                    user: updated,
                    name: updated.name,
                    email: updated.email
                });
                LiveView.putFlash(updatedSocket, FlashType.Info, "Profile updated.");
            case Error(_changeset):
                LiveView.putFlash(socket, FlashType.Error, "Could not update profile. Please try again.");
        };
    }

    @:keep
    public static function render(assigns: ProfileLiveRenderAssigns): String {
        var renderAssigns: Assigns<ProfileLiveRenderAssigns> = assigns;
        renderAssigns = Component.assign(renderAssigns, "flash_info", PhoenixFlash.get(assigns.flash, "info"));
        renderAssigns = Component.assign(renderAssigns, "flash_error", PhoenixFlash.get(assigns.flash, "error"));
        assigns = renderAssigns;

        return HXX.hxx('
            <div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-blue-900">
                <div class="container mx-auto px-4 py-10 max-w-3xl">
                    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-8">
                        <div class="flex items-start justify-between gap-4 mb-6">
                            <div>
                                <h1 class="text-3xl font-bold text-gray-900 dark:text-white">Profile</h1>
                                <p class="text-gray-600 dark:text-gray-300">Edit your display name and email.</p>
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

                        <if {!@signed_in}>
                            <div class="border border-gray-200 dark:border-gray-700 rounded-lg p-6">
                                <div class="font-semibold text-gray-900 dark:text-white mb-2">Not signed in</div>
                                <p class="text-gray-600 dark:text-gray-300 mb-4">
                                    Sign in to create a user and manage a profile.
                                </p>
                                <a href="/login" class="inline-block px-4 py-2 bg-gray-900 text-white rounded-lg hover:bg-gray-800">
                                    Go to sign in
                                </a>
                            </div>
                        </if>

                        <if {@signed_in}>
                            <div class="space-y-4">
                                <form phx-submit="save_profile" class="space-y-4">
                                    <div>
                                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-200 mb-1">Name</label>
                                        <input name="name" type="text" required minlength="2" value={@name}
                                            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white"/>
                                    </div>

                                    <div>
                                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-200 mb-1">Email</label>
                                        <input name="email" type="email" required value={@email}
                                            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white"/>
                                    </div>

                                    <div class="pt-2">
                                        <button type="submit" class="px-5 py-2.5 bg-gradient-to-r from-blue-500 to-indigo-600 text-white font-medium rounded-lg hover:from-blue-600 hover:to-indigo-700 transition-all duration-200 shadow-md">
                                            Save
                                        </button>
                                    </div>
                                </form>

                                <form action="/auth/logout" method="post">
                                    <input type="hidden" name="_csrf_token" value=${CSRFProtection.get_csrf_token()}/>
                                    <button type="submit" class="px-4 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300 dark:bg-gray-700 dark:text-white dark:hover:bg-gray-600">
                                        Sign out
                                    </button>
                                </form>
                            </div>
                        </if>
                    </div>
                </div>
            </div>
        ');
    }
}
