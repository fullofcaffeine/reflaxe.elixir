package server.live;

import contexts.Users;
import contexts.Users.User;
import phoenix.Phoenix.LiveView;  // Use the comprehensive Phoenix module version
import phoenix.LiveSocket;  // Type-safe socket wrapper
import phoenix.Phoenix.Socket;
import ecto.Changeset;
import elixir.types.Result;  // For type-safe error handling
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
    Search(params: {search_term: String});
    FilterStatus(params: {status: String});
    ClearSearch;
    
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
        var users = Users.listUsers(null);
        var liveSocket: LiveSocket<UserLiveAssigns> = socket;
        
        return {
            status: "ok", 
            socket: liveSocket.merge({
                users: users,
                selectedUser: null,
                changeset: Users.changeUser(null),
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
                
            case Search(params):
                handleSearch(params.search_term, liveSocket);
                
            case FilterStatus(params):
                handleFilterStatus(params.status, liveSocket);
                
            case ClearSearch:
                handleClearSearch(liveSocket);
                
            case Cancel:
                handleCancel(liveSocket);
        }
    }
    
    static function handleNewUser(socket: LiveSocket<UserLiveAssigns>): {status: String, socket: Socket<UserLiveAssigns>} {
        var changeset = Users.changeUser(null);
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
    
    static function handleEditUser(userId: Int, socket: LiveSocket<UserLiveAssigns>): {status: String, socket: Socket<UserLiveAssigns>} {
        var selectedUser = Users.getUser(userId);
        var changeset = Users.changeUser(selectedUser);
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
    
    static function handleSaveUser(params: {user: Dynamic}, socket: LiveSocket<UserLiveAssigns>): {status: String, socket: Socket<UserLiveAssigns>} {
        var userParams = params.user;
        var selectedUser = socket.assigns.selectedUser;
        var result = selectedUser == null 
            ? Users.createUser(userParams)
            : Users.updateUser(selectedUser, userParams);
            
        return switch(result) {
            case Ok(user):
                // Successfully created/updated user
                var users = Users.listUsers(null);
                
                {
                    status: "noreply",
                    socket: socket.merge({
                        users: users,
                        showForm: false,
                        selectedUser: null,
                        changeset: Users.changeUser(null)
                    })
                };
                
            case Error(changeset):
                // Validation errors in changeset
                {
                    status: "noreply",
                    socket: socket.assign(_.changeset, changeset)
                };
        }
    }
    
    static function handleDeleteUser(userId: Int, socket: LiveSocket<UserLiveAssigns>): {status: String, socket: Socket<UserLiveAssigns>} {
        var user = Users.getUser(userId);
        var result = Users.deleteUser(user);
        
        return switch(result) {
            case Ok(deletedUser):
                // Successfully deleted user
                var users = Users.listUsers(null);
                {
                    status: "noreply",
                    socket: socket.assign(_.users, users)
                };
                
            case Error(changeset):
                // Failed to delete (e.g., foreign key constraint)
                // Could add error message to socket here
                {status: "noreply", socket: socket};
        }
    }
    
    static function handleSearch(searchTerm: String, socket: LiveSocket<UserLiveAssigns>): {status: String, socket: Socket<UserLiveAssigns>} {
        // Use the new filtering functionality
        var filter = searchTerm.length > 0 
            ? {
                name: searchTerm,
                email: searchTerm,
                isActive: null
              }
            : null;
            
        var users = Users.listUsers(filter);
            
        return {
            status: "noreply",
            socket: socket.merge({
                users: users,
                searchTerm: searchTerm
            })
        };
    }
    
    static function handleFilterStatus(status: String, socket: LiveSocket<UserLiveAssigns>): {status: String, socket: Socket<UserLiveAssigns>} {
        var filter = status.length > 0 
            ? {
                name: null,
                email: null,
                isActive: status == "active"
              }
            : null;
            
        var users = Users.listUsers(filter);
            
        return {
            status: "noreply",
            socket: socket.assign(_.users, users)
        };
    }
    
    static function handleClearSearch(socket: LiveSocket<UserLiveAssigns>): {status: String, socket: Socket<UserLiveAssigns>} {
        var users = Users.listUsers(null);
        
        return {
            status: "noreply",
            socket: socket.merge({
                users: users,
                searchTerm: ""
            })
        };
    }
    
    static function handleCancel(socket: LiveSocket<UserLiveAssigns>): {status: String, socket: Socket<UserLiveAssigns>} {
        return {
            status: "noreply",
            socket: socket.merge({
                showForm: false,
                selectedUser: null,
                changeset: Users.changeUser(null)
            })
        };
    }
    
    static function render(assigns: Dynamic): String {
        return HXX.hxx('
        <div class="min-h-screen bg-gray-50 py-8">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <!-- Header with gradient background -->
                <div class="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-lg shadow-lg p-6 mb-8">
                    <div class="flex justify-between items-center">
                        <div>
                            <h1 class="text-3xl font-bold text-white">User Management</h1>
                            <p class="text-blue-100 mt-1">Manage your application users</p>
                        </div>
                        <button 
                            phx-click="new_user" 
                            class="bg-white text-blue-600 hover:bg-blue-50 px-6 py-3 rounded-lg font-semibold flex items-center gap-2 transition-colors shadow-md"
                        >
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
                            </svg>
                            New User
                        </button>
                    </div>
                </div>
                
                <!-- Search and Filter Section -->
                <div class="bg-white rounded-lg shadow-md p-6 mb-6">
                    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <div class="md:col-span-2">
                            <label class="block text-sm font-medium text-gray-700 mb-2">Search Users</label>
                            <form phx-change="search" phx-submit="search">
                                <div class="relative">
                                    <input 
                                        name="search_term"
                                        value={@searchTerm}
                                        placeholder="Search by name or email..."
                                        type="text"
                                        class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                                    />
                                    <svg class="absolute left-3 top-2.5 w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                                    </svg>
                                </div>
                            </form>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-2">Filter by Status</label>
                            <select phx-change="filter_status" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
                                <option value="">All Users</option>
                                <option value="active">Active</option>
                                <option value="inactive">Inactive</option>
                            </select>
                        </div>
                    </div>
                    
                    <%= if @searchTerm != "" do %>
                        <div class="mt-4 flex items-center text-sm text-gray-600">
                            <span>Showing results for: <span class="font-semibold">{@searchTerm}</span></span>
                            <button phx-click="clear_search" class="ml-2 text-blue-600 hover:text-blue-800">Clear</button>
                        </div>
                    <% end %>
                </div>
                
                ${renderUserList(assigns)}
                ${renderUserForm(assigns)}
            </div>
        </div>
        ');
    }
    
    static function renderUserList(assigns: Dynamic): String {
        return HXX.hxx('
        <div class="bg-white rounded-lg shadow-md overflow-hidden">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Name
                        </th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Email
                        </th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Age
                        </th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Status
                        </th>
                        <th scope="col" class="relative px-6 py-3">
                            <span class="sr-only">Actions</span>
                        </th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    <%= for user <- @users do %>
                        <tr class="hover:bg-gray-50 transition-colors">
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="flex items-center">
                                    <div class="flex-shrink-0 h-10 w-10">
                                        <div class="h-10 w-10 rounded-full bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center text-white font-semibold">
                                            <%= String.first(user.name) %>
                                        </div>
                                    </div>
                                    <div class="ml-4">
                                        <div class="text-sm font-medium text-gray-900">
                                            <%= user.name %>
                                        </div>
                                    </div>
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900"><%= user.email %></div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900"><%= user.age %></div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <%= if user.is_active do %>
                                    <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                                        Active
                                    </span>
                                <% else %>
                                    <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800">
                                        Inactive
                                    </span>
                                <% end %>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                <button 
                                    phx-click="edit_user" 
                                    phx-value-id={user.id}
                                    class="text-indigo-600 hover:text-indigo-900 mr-3"
                                >
                                    Edit
                                </button>
                                <button 
                                    phx-click="delete_user" 
                                    phx-value-id={user.id}
                                    data-confirm="Are you sure you want to delete this user?"
                                    class="text-red-600 hover:text-red-900"
                                >
                                    Delete
                                </button>
                            </td>
                        </tr>
                    <% end %>
                </tbody>
            </table>
            
            <%= if length(@users) == 0 do %>
                <div class="text-center py-12">
                    <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
                    </svg>
                    <h3 class="mt-2 text-sm font-medium text-gray-900">No users found</h3>
                    <p class="mt-1 text-sm text-gray-500">
                        <%= if @searchTerm != "" do %>
                            Try adjusting your search criteria
                        <% else %>
                            Get started by creating a new user
                        <% end %>
                    </p>
                </div>
            <% end %>
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