package live;

import contexts.Users;
import contexts.Users.User;
import elixir.ElixirMap;
import elixir.types.Term;
import phoenix.Phoenix.EventParams;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.MountParams;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Session;
import phoenix.Phoenix.Socket;

private typedef UserLiveAssigns = {
	users:Array<User>,
	selectedUser:Null<User>,
	changeset:Term,
	searchTerm:String,
	showForm:Bool
}

// ---------------------------------------------------------------------
// Minimal CoreComponents
//
// NOTE: This example keeps lightweight component stubs local to avoid relying
// on generated Phoenix CoreComponents. They are intentionally small and only
// aim to keep the example compileable under --warnings-as-errors.
// ---------------------------------------------------------------------

private typedef ButtonAssigns = {
	?type:String,
	?disabled:Bool,
	inner_content:String
};

private typedef IconAssigns = {
	name:String
};

private typedef InputAssigns = {
	?type:String,
	?name:String,
	?value:String,
	?placeholder:String,
	?required:Bool,
	?label:String,
	?field:Term
};

private typedef LabelAssigns = {
	inner_content:String
};

private typedef ErrorAssigns = {
	?field:Term
};

/**
 * Phoenix LiveView for user management
 * Demonstrates real-time user CRUD operations
 */
// @:liveview: compiles this module as a Phoenix LiveView with LiveView callback semantics.

@:liveview
class UserLive {
	public static function mount(_params:MountParams, _session:Session, socket:Socket<UserLiveAssigns>):MountResult<UserLiveAssigns> {
		var users = Users.list_users();

		var assigns:UserLiveAssigns = {
			users: users,
			selectedUser: null,
			changeset: Users.change_user(null),
			searchTerm: "",
			showForm: false
		};

		return Ok(socket.assign(assigns));
	}

	public static function handleEvent(event:String, params:EventParams, socket:Socket<UserLiveAssigns>):HandleEventResult<UserLiveAssigns> {
		return switch (event) {
			case "new_user":
				handleNewUser(socket);

			case "edit_user":
				handleEditUser(params, socket);

			case "save_user":
				handleSaveUser(params, socket);

			case "delete_user":
				handleDeleteUser(params, socket);

			case "search":
				handleSearch(params, socket);

			case "cancel":
				handleCancel(socket);

			default:
				NoReply(socket);
		};
	}

	private static function handleNewUser(socket:Socket<UserLiveAssigns>):HandleEventResult<UserLiveAssigns> {
		var updated = socket.assign({
			changeset: Users.change_user(null),
			selectedUser: null,
			showForm: true
		});
		return NoReply(updated);
	}

	private static function handleEditUser(params:EventParams, socket:Socket<UserLiveAssigns>):HandleEventResult<UserLiveAssigns> {
		var userId = getIntParam(params, "id");
		if (userId == null)
			return NoReply(socket);

		var selectedUser = Users.get_user(userId);
		var updated = socket.assign({
			selectedUser: selectedUser,
			changeset: Users.change_user(selectedUser),
			showForm: true
		});
		return NoReply(updated);
	}

	private static function handleSaveUser(params:EventParams, socket:Socket<UserLiveAssigns>):HandleEventResult<UserLiveAssigns> {
		var userParams:Term = ElixirMap.get(params, "user");
		var result = socket.assigns.selectedUser == null ? Users.create_user(userParams) : Users.update_user(socket.assigns.selectedUser, userParams);

		return switch (result.status) {
			case "ok":
				var users = Users.list_users();
				var updated = socket.assign({
					users: users,
					showForm: false,
					selectedUser: null,
					changeset: Users.change_user(null)
				});
				NoReply(updated);

			case "error":
				var updated = socket.assign({changeset: result.changeset});
				NoReply(updated);

			default:
				NoReply(socket);
		}
	}

	private static function handleDeleteUser(params:EventParams, socket:Socket<UserLiveAssigns>):HandleEventResult<UserLiveAssigns> {
		var userId = getIntParam(params, "id");
		if (userId == null)
			return NoReply(socket);

		var user = Users.get_user(userId);
		var result = Users.delete_user(user);

		if (result.status == "ok") {
			var users = Users.list_users();
			var updated = socket.assign({users: users});
			return NoReply(updated);
		}

		return NoReply(socket);
	}

	private static function handleSearch(params:EventParams, socket:Socket<UserLiveAssigns>):HandleEventResult<UserLiveAssigns> {
		var searchTerm = getStringParam(params, "search");
		if (searchTerm == null)
			searchTerm = "";

		var users = searchTerm.length > 0 ? Users.search_users(searchTerm) : Users.list_users();

		var updated = socket.assign({users: users, searchTerm: searchTerm});
		return NoReply(updated);
	}

	private static function handleCancel(socket:Socket<UserLiveAssigns>):HandleEventResult<UserLiveAssigns> {
		var updated = socket.assign({
			showForm: false,
			selectedUser: null,
			changeset: Users.change_user(null)
		});
		return NoReply(updated);
	}

	public static function render(assigns:UserLiveAssigns):String {
		return <div class="user-management">
            <div class="header">
                <h1>User Management</h1>
                <.button phx-click="new_user" class="btn-primary">
                    <.icon name="plus" /> New User
                </.button>
            </div>

            <div class="search-bar">
                <.form for=${emptyFormTarget()} phx-change="search">
                    <.input
                        name="search"
                        value=${assigns.searchTerm}
                        placeholder="Search users..."
                        type="search"
                    />
                </.form>
            </div>

            ${renderUserList(assigns)}
            ${renderUserForm(assigns)}
        </div>;
	}

	private static function renderUserList(assigns:UserLiveAssigns):String {
		return <div class="users-list">
            <table class="table">
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Email</th>
                        <th>Age</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    ${assigns.users.map(renderUserRow).join("")}
                </tbody>
            </table>
        </div>;
	}

	private static function renderUserRow(user:User):String {
		return <tr>
            <td>${user.name}</td>
            <td>${user.email}</td>
            <td>${user.age}</td>
            <td>
                <span class=${"status " + (user.active ? "active" : "inactive")}>
                    ${user.active ? "Active" : "Inactive"}
                </span>
            </td>
            <td class="actions">
                <.button phx-click="edit_user" phx-value-id=${user.id} size="sm">
                    Edit
                </.button>
                <.button
                    phx-click="delete_user"
                    phx-value-id=${user.id}
                    data-confirm="Are you sure?"
                    variant="danger"
                    size="sm"
                >
                    Delete
                </.button>
            </td>
        </tr>;
	}

	private static function renderUserForm(assigns:UserLiveAssigns):String {
		if (!assigns.showForm)
			return "";

		return <div class="modal">
            <div class="modal-content">
                <div class="modal-header">
                    <h2>${assigns.selectedUser == null ? "New User" : "Edit User"}</h2>
                    <button phx-click="cancel" class="close">&times;</button>
                </div>

                <.form for=${assigns.changeset} phx-submit="save_user">
                    <div class="form-group">
                        <.label for="name">Name</.label>
                        <.input name="user[name]" type="text" required />
                        <.error />
                    </div>

                    <div class="form-group">
                        <.label for="email">Email</.label>
                        <.input name="user[email]" type="email" required />
                        <.error />
                    </div>

                    <div class="form-group">
                        <.label for="age">Age</.label>
                        <.input name="user[age]" type="number" />
                        <.error />
                    </div>

                    <div class="form-group">
                        <.input
                            name="user[active]"
                            type="checkbox"
                            label="Active"
                        />
                    </div>

                    <div class="form-actions">
                        <.button type="submit">
                            ${assigns.selectedUser == null ? "Create" : "Update"} User
                        </.button>
                        <.button type="button" phx-click="cancel" variant="secondary">
                            Cancel
                        </.button>
                    </div>
                </.form>
            </div>
        </div>;
	}

	private static inline function emptyFormTarget():Term {
		return cast {};
	}

	private static function getStringParam(params:Term, key:String):Null<String> {
		var value:Term = ElixirMap.get(params, key);
		return value == null ? null : Std.string(value);
	}

	private static function getIntParam(params:Term, key:String):Null<Int> {
		var value = getStringParam(params, key);
		if (value == null)
			return null;
		return Std.parseInt(value);
	}

	public static function button(assigns:ButtonAssigns):String {
		return <button
            type=${assigns.type != null ? assigns.type : "button"}
            disabled=${assigns.disabled}
        >
            ${assigns.inner_content}
        </button>;
	}

	public static function icon(assigns:IconAssigns):String {
		return <span class=${"icon icon-" + assigns.name}></span>;
	}

	public static function input(assigns:InputAssigns):String {
		return <input
            type=${assigns.type != null ? assigns.type : "text"}
            name=${assigns.name}
            value=${assigns.value}
            placeholder=${assigns.placeholder}
            required=${assigns.required}
        ></input>;
	}

	public static function label(assigns:LabelAssigns):String {
		return <label>
            ${assigns.inner_content}
        </label>;
	}

	public static function error(assigns:ErrorAssigns):String {
		// Keep minimal to avoid coupling to Ecto.Changeset error formatting here.
		return <span class="error"></span>;
	}

	public static function main():Void {
		// @:liveview: compiles this module as a Phoenix LiveView with LiveView callback semantics.
		trace("UserLive with @:liveview annotation compiled successfully!");
	}
}
