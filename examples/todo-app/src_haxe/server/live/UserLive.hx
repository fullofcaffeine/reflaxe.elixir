package server.live;

import contexts.Users;
import contexts.Users.User;
import phoenix.Phoenix.LiveView;  // Use the comprehensive Phoenix module version
import phoenix.LiveSocket;  // Type-safe socket wrapper
import phoenix.Phoenix.Socket;
import ecto.Changeset;
import HXX;  // Import HXX for template rendering

// HXX template calls are processed at compile-time by the Reflaxe.Elixir compiler

/**
 * Type-safe event definitions for UserLive.
 * 
 * This enum replaces string-based events with compile-time validated ADTs.
 * Each event variant carries its own strongly-typed parameters.
 */
enum UserLiveEvent {
    // User CRUD operations
    NewUser;
    EditUser(id: Int);
    SaveUser(params: {user: Dynamic}); // User form params
    DeleteUser(id: Int);
    
    // Search and filtering
    Search(query: String);
    
    // UI interactions
    Cancel;
}

/**
 * Type-safe assigns structure for UserLive socket
 */
typedef UserLiveAssigns = {
    var users: Array<User>;
    var selectedUser: Null<User>;
    var changeset: Changeset<User, Dynamic>;
    var searchTerm: String;
    var showForm: Bool;
}

/**
 * Phoenix LiveView for user management
 * Demonstrates real-time user CRUD operations
 */
@:native("TodoAppWeb.UserLive")
@:liveview
class UserLive {
    static function mount(_params: Dynamic, _session: Dynamic, socket: Socket<UserLiveAssigns>): {status: String, socket: Socket<UserLiveAssigns>} {
        var users = Users.list_users(null);
        var liveSocket: LiveSocket<UserLiveAssigns> = socket;
        
        return {
            status: "ok", 
            socket: liveSocket.merge({
                users: users,
                selectedUser: null,
                changeset: Users.change_user(null),
                searchTerm: "",
                showForm: false
            })
        };
    }
    
    static function handleEvent(event: UserLiveEvent, socket: Socket<UserLiveAssigns>): {status: String, socket: Socket<UserLiveAssigns>} {
        var liveSocket: LiveSocket<UserLiveAssigns> = socket;
        return switch(event) {
            case NewUser:
                handleNewUser(liveSocket);
                
            case EditUser(id):
                handleEditUser(id, liveSocket);
                
            case SaveUser(params):
                handleSaveUser(params, liveSocket);
                
            case DeleteUser(id):
                handleDeleteUser(id, liveSocket);
                
            case Search(query):
                handleSearch(query, liveSocket);
                
            case Cancel:
                handleCancel(liveSocket);
        }
    }
    
    static function handleNewUser(socket: LiveSocket<UserLiveAssigns>): {status: String, socket: LiveSocket<UserLiveAssigns>} {
        var changeset = Users.change_user(null);
        var selectedUser = null;
        var showForm = true;
        
        return {
            status: "noreply",
            socket: socket.merge({
                changeset: changeset,
                selectedUser: selectedUser,
                showForm: showForm
            })
        };
    }
    
    static function handleEditUser(userId: Int, socket: LiveSocket<UserLiveAssigns>): {status: String, socket: LiveSocket<UserLiveAssigns>} {
        var selectedUser = Users.get_user(userId);
        var changeset = Users.change_user(selectedUser);
        var showForm = true;
        
        return {
            status: "noreply",
            socket: socket.merge({
                selectedUser: selectedUser,
                changeset: changeset,
                showForm: showForm
            })
        };
    }
    
    static function handleSaveUser(params: {user: Dynamic}, socket: LiveSocket<UserLiveAssigns>): {status: String, socket: LiveSocket<UserLiveAssigns>} {
        var userParams = params.user;
        var selectedUser = socket.assigns.selectedUser;
        var result = selectedUser == null 
            ? Users.create_user(userParams)
            : Users.update_user(selectedUser, userParams);
            
        return switch(result.status) {
            case "ok":
                var users = Users.list_users(null);
                var showForm = false;
                
                {
                    status: "noreply",
                    socket: socket.merge({
                        users: users,
                        showForm: showForm,
                        selectedUser: null,
                        changeset: Users.change_user(null)
                    })
                };
                
            case "error":
                {
                    status: "noreply",
                    socket: socket.assign(_.changeset, result.changeset)
                };
                
            default:
                {status: "noreply", socket: liveSocket};
        }
    }
    
    static function handleDeleteUser(userId: Int, socket: LiveSocket<UserLiveAssigns>): {status: String, socket: LiveSocket<UserLiveAssigns>} {
        var user = Users.get_user(userId);
        var result = Users.delete_user(user);
        
        if (result.status == "ok") {
            var users = Users.list_users(null);
            
            return {
                status: "noreply",
                socket: socket.assign(_.users, users)
            };
        }
        
        return {status: "noreply", socket: socket};
    }
    
    static function handleSearch(searchTerm: String, socket: LiveSocket<UserLiveAssigns>): {status: String, socket: LiveSocket<UserLiveAssigns>} {
        
        var users = searchTerm.length > 0 
            ? Users.search_users(searchTerm)
            : Users.list_users(null);
            
        return {
            status: "noreply",
            socket: socket.merge({
                users: users,
                searchTerm: searchTerm
            })
        };
    }
    
    static function handleCancel(socket: LiveSocket<UserLiveAssigns>): {status: String, socket: LiveSocket<UserLiveAssigns>} {
        return {
            status: "noreply",
            socket: socket.merge({
                showForm: false,
                selectedUser: null,
                changeset: Users.change_user(null)
            })
        };
    }
    
    static function render(assigns: Dynamic): String {
        return HXX.hxx('
        <div class="user-management">
            <div class="header">
                <h1>User Management</h1>
                <.button phx-click="new_user" class="btn-primary">
                    <.icon name="plus" /> New User
                </.button>
            </div>
            
            <div class="search-bar">
                <.form phx-change="search">
                    <.input 
                        name="search" 
                        value={@searchTerm}
                        placeholder="Search users..."
                        type="search"
                    />
                </.form>
            </div>
            
            ${renderUserList(assigns)}
            ${renderUserForm(assigns)}
        </div>
        ');
    }
    
    static function renderUserList(assigns: Dynamic): String {
        return HXX.hxx('
        <div class="users-list">
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
                    <%= for user <- @users do %>
                        <%= render_user_row(%{user: user}) %>
                    <% end %>
                </tbody>
            </table>
        </div>
        ');
    }
    
    static function renderUserRow(assigns: Dynamic): String {
        var user = assigns.user;
        return HXX.hxx('
        <tr>
            <td>${user.name}</td>
            <td>${user.email}</td>
            <td>${user.age}</td>
            <td>
                <span class={getStatusClass(user.active)}>
                    ${getStatusText(user.active)}
                </span>
            </td>
            <td class="actions">
                <.button phx-click="edit_user" phx-value-id={user.id} size="sm">
                    Edit
                </.button>
                <.button 
                    phx-click="delete_user" 
                    phx-value-id={user.id} 
                    data-confirm="Are you sure?"
                    variant="danger"
                    size="sm"
                >
                    Delete
                </.button>
            </td>
        </tr>
        ');
    }
    
    /**
     * Get CSS class for user status
     */
    private static function getStatusClass(active: Bool): String {
        return active ? "status active" : "status inactive";
    }
    
    /**
     * Get display text for user status
     */
    private static function getStatusText(active: Bool): String {
        return active ? "Active" : "Inactive";
    }
    
    static function renderUserForm(assigns: Dynamic): String {
        if (!assigns.showForm) return "";
        
        return HXX.hxx('
        <div class="modal">
            <div class="modal-content">
                <div class="modal-header">
                    <h2><%= if @selectedUser, do: "Edit User", else: "New User" %></h2>
                    <button phx-click="cancel" class="close">&times;</button>
                </div>
                
                <.form for={@changeset} phx-submit="save_user">
                    <div class="form-group">
                        <.label for="name">Name</.label>
                        <.input field={@changeset[:name]} type="text" required />
                        <.error field={@changeset[:name]} />
                    </div>
                    
                    <div class="form-group">
                        <.label for="email">Email</.label>
                        <.input field={@changeset[:email]} type="email" required />
                        <.error field={@changeset[:email]} />
                    </div>
                    
                    <div class="form-group">
                        <.label for="age">Age</.label>
                        <.input field={@changeset[:age]} type="number" />
                        <.error field={@changeset[:age]} />
                    </div>
                    
                    <div class="form-group">
                        <.input 
                            field={@changeset[:active]} 
                            type="checkbox" 
                            label="Active"
                        />
                    </div>
                    
                    <div class="form-actions">
                        <.button type="submit">
                            <%= if @selectedUser, do: "Update", else: "Create" %> User
                        </.button>
                        <.button type="button" phx-click="cancel" variant="secondary">
                            Cancel
                        </.button>
                    </div>
                </.form>
            </div>
        </div>
        ');
    }
    
    // Main function for compilation testing
    public static function main(): Void {
        trace("UserLive with @:liveview annotation compiled successfully!");
    }
}