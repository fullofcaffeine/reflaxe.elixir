package server.live;

import contexts.Users;
import contexts.Users.User;

// HXX template calls are processed at compile-time by the Reflaxe.Elixir compiler

/**
 * Phoenix LiveView for user management
 * Demonstrates real-time user CRUD operations
 */
@:native("TodoAppWeb.UserLive")
@:liveview
class UserLive {
    static function mount(_params: Dynamic, _session: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        var users = Users.list_users(null);
        
        return {
            status: "ok", 
            socket: assign_multiple(socket, {
                users: users,
                selectedUser: null,
                changeset: Users.change_user(null),
                searchTerm: "",
                showForm: false
            })
        };
    }
    
    static function handle_event(event: String, params: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        return switch(event) {
            case "new_user":
                handleNewUser(params, socket);
                
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
                {status: "noreply", socket: socket};
        }
    }
    
    static function handleNewUser(params: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        var changeset = Users.change_user(null);
        var selectedUser = null;
        var showForm = true;
        
        return {
            status: "noreply",
            socket: assign_multiple(socket, {
                changeset: changeset,
                selectedUser: selectedUser,
                showForm: showForm
            })
        };
    }
    
    static function handleEditUser(params: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        var userId = params.id;
        var selectedUser = Users.get_user(userId);
        var changeset = Users.change_user(selectedUser);
        var showForm = true;
        
        return {
            status: "noreply",
            socket: assign_multiple(socket, {
                selectedUser: selectedUser,
                changeset: changeset,
                showForm: showForm
            })
        };
    }
    
    static function handleSaveUser(params: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        var userParams = params.user;
        var selectedUser = Reflect.field(socket.assigns, "selectedUser");
        var result = selectedUser == null 
            ? Users.create_user(userParams)
            : Users.update_user(selectedUser, userParams);
            
        return switch(result.status) {
            case "ok":
                var users = Users.list_users(null);
                var showForm = false;
                
                {
                    status: "noreply",
                    socket: assign_multiple(socket, {
                        users: users,
                        showForm: showForm,
                        selectedUser: null,
                        changeset: Users.change_user(null)
                    })
                };
                
            case "error":
                {
                    status: "noreply",
                    socket: assign(socket, "changeset", result.changeset)
                };
                
            default:
                {status: "noreply", socket: socket};
        }
    }
    
    static function handleDeleteUser(params: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        var userId = params.id;
        var user = Users.get_user(userId);
        var result = Users.delete_user(user);
        
        if (result.status == "ok") {
            var users = Users.list_users(null);
            
            return {
                status: "noreply",
                socket: assign(socket, "users", users)
            };
        }
        
        return {status: "noreply", socket: socket};
    }
    
    static function handleSearch(params: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        var searchTerm = params.search;
        
        var users = searchTerm.length > 0 
            ? Users.search_users(searchTerm)
            : Users.list_users(null);
            
        return {
            status: "noreply",
            socket: assign_multiple(socket, {
                users: users,
                searchTerm: searchTerm
            })
        };
    }
    
    static function handleCancel(socket: Dynamic): {status: String, socket: Dynamic} {
        return {
            status: "noreply",
            socket: assign_multiple(socket, {
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
    
    // Helper functions that map to Phoenix.Component functions
    // These allow the Haxe code to compile and will be filtered out during code generation
    // since Phoenix.Component provides these functions
    static function assign(socket: Dynamic, key: String, value: Dynamic): Dynamic {
        return socket;
    }
    
    static function assign_multiple(socket: Dynamic, assigns: Dynamic): Dynamic {
        return socket;
    }
    
    // Main function for compilation testing
    public static function main(): Void {
        trace("UserLive with @:liveview annotation compiled successfully!");
    }
}