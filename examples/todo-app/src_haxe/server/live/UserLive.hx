package server.live;

import contexts.Users;
import contexts.Users.User;

// HXX template calls are processed at compile-time by the Reflaxe.Elixir compiler

/**
 * Phoenix LiveView for user management
 * Demonstrates real-time user CRUD operations
 */
@:liveview
class UserLive {
    var users: Array<User> = [];
    var selectedUser: Null<User> = null;
    var changeset: Dynamic = null;
    var searchTerm: String = "";
    var showForm: Bool = false;
    
    function mount(_params: Dynamic, _session: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        var users = Users.list_users();
        
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
    
    function handle_event(event: String, params: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
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
    
    function handleNewUser(params: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
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
    
    function handleEditUser(params: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
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
    
    function handleSaveUser(params: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        var userParams = params.user;
        var result = selectedUser == null 
            ? Users.create_user(userParams)
            : Users.update_user(selectedUser, userParams);
            
        return switch(result.status) {
            case "ok":
                var users = Users.list_users();
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
    
    function handleDeleteUser(params: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        var userId = params.id;
        var user = Users.get_user(userId);
        var result = Users.delete_user(user);
        
        if (result.status == "ok") {
            var users = Users.list_users();
            
            return {
                status: "noreply",
                socket: assign(socket, "users", users)
            };
        }
        
        return {status: "noreply", socket: socket};
    }
    
    function handleSearch(params: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        var searchTerm = params.search;
        
        var users = searchTerm.length > 0 
            ? Users.search_users(searchTerm)
            : Users.list_users();
            
        return {
            status: "noreply",
            socket: assign_multiple(socket, {
                users: users,
                searchTerm: searchTerm
            })
        };
    }
    
    function handleCancel(socket: Dynamic): {status: String, socket: Dynamic} {
        return {
            status: "noreply",
            socket: assign_multiple(socket, {
                showForm: false,
                selectedUser: null,
                changeset: Users.change_user(null)
            })
        };
    }
    
    function render(assigns: Dynamic): String {
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
    
    function renderUserList(assigns: Dynamic): String {
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
                        <%= render_user_row(user) %>
                    <% end %>
                </tbody>
            </table>
        </div>
        ');
    }
    
    function renderUserRow(user: User): String {
        return HXX.hxx('
        <tr>
            <td>${user.name}</td>
            <td>${user.email}</td>
            <td>${user.age}</td>
            <td>
                <span class="status ${user.active ? "active" : "inactive"}">
                    ${user.active ? "Active" : "Inactive"}
                </span>
            </td>
            <td class="actions">
                <.button phx-click="edit_user" phx-value-id="${user.id}" size="sm">
                    Edit
                </.button>
                <.button 
                    phx-click="delete_user" 
                    phx-value-id="${user.id}" 
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
    
    function renderUserForm(assigns: Dynamic): String {
        if (!assigns.showForm) return "";
        
        var title = assigns.selectedUser == null ? "New User" : "Edit User";
        
        return HXX.hxx('
        <div class="modal">
            <div class="modal-content">
                <div class="modal-header">
                    <h2>${title}</h2>
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
                            ${assigns.selectedUser == null ? "Create" : "Update"} User
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
    
    // Helper functions
    static function assign(socket: Dynamic, key: String, value: Dynamic): Dynamic return socket;
    static function assign_multiple(socket: Dynamic, assigns: Dynamic): Dynamic return socket;
    
    // Main function for compilation testing
    public static function main(): Void {
        trace("UserLive with @:liveview annotation compiled successfully!");
    }
}