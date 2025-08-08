package phoenix;

/**
 * Example Phoenix LiveView
 * Tests LiveView generation with real-time features
 */
class UserLiveView extends Phoenix.LiveView {
    
    /**
     * Mount the LiveView with initial data
     */
    public function mount(params: Dynamic, session: Dynamic, socket: Phoenix.Socket): Dynamic {
        var users = UserContext.list_users();
        
        socket = Phoenix.LiveView.assign(socket, "users", users);
        socket = Phoenix.LiveView.assign(socket, "filter", "");
        socket = Phoenix.LiveView.assign(socket, "changeset", User.changeset(new User(), {}));
        
        return {ok: socket};
    }
    
    /**
     * Handle form submission to create new user
     */
    public function handle_event("save_user", params: Dynamic, socket: Phoenix.Socket): Dynamic {
        switch (UserContext.create_user(params.user)) {
            case {ok: user}:
                // Add the new user to the list and clear form
                var users = socket.assigns.users;
                users.push(user);
                
                socket = Phoenix.LiveView.assign(socket, "users", users);
                socket = Phoenix.LiveView.assign(socket, "changeset", User.changeset(new User(), {}));
                socket = Phoenix.LiveView.put_flash(socket, "info", "User created successfully");
                
                return {noreply: socket};
                
            case {error: changeset}:
                socket = Phoenix.LiveView.assign(socket, "changeset", changeset);
                return {noreply: socket};
        }
    }
    
    /**
     * Handle user deletion
     */
    public function handle_event("delete_user", params: Dynamic, socket: Phoenix.Socket): Dynamic {
        var user = UserContext.get_user!(params.id);
        
        switch (UserContext.delete_user(user)) {
            case {ok: _}:
                // Remove user from the list
                var users = socket.assigns.users.filter(u -> u.id != user.id);
                socket = Phoenix.LiveView.assign(socket, "users", users);
                socket = Phoenix.LiveView.put_flash(socket, "info", "User deleted");
                
                return {noreply: socket};
                
            case {error: _}:
                socket = Phoenix.LiveView.put_flash(socket, "error", "Error deleting user");
                return {noreply: socket};
        }
    }
    
    /**
     * Handle search/filter input
     */
    public function handle_event("filter_users", params: Dynamic, socket: Phoenix.Socket): Dynamic {
        var filter = params.filter != null ? params.filter : "";
        
        var users = if (filter == "") {
            UserContext.list_users();
        } else {
            UserContext.find_users_by_email('%${filter}%');
        };
        
        socket = Phoenix.LiveView.assign(socket, "users", users);
        socket = Phoenix.LiveView.assign(socket, "filter", filter);
        
        return {noreply: socket};
    }
    
    /**
     * Handle form validation
     */
    public function handle_event("validate_user", params: Dynamic, socket: Phoenix.Socket): Dynamic {
        var changeset = User.changeset(new User(), params.user);
        
        // Mark changeset for validation without saving
        socket = Phoenix.LiveView.assign(socket, "changeset", changeset);
        
        return {noreply: socket};
    }
    
    /**
     * Render the LiveView template
     * This would typically be in a .heex template file in Phoenix
     */
    public function render(assigns: Dynamic): String {
        return '''
        <div class="user-live-view">
          <h1>Users</h1>
          
          <!-- Search/Filter -->
          <form phx-change="filter_users">
            <input type="text" name="filter" value="${assigns.filter}" placeholder="Search users..." />
          </form>
          
          <!-- New User Form -->
          <form phx-submit="save_user" phx-change="validate_user">
            <input type="text" name="user[name]" placeholder="Name" required />
            <input type="email" name="user[email]" placeholder="Email" required />
            <button type="submit">Create User</button>
          </form>
          
          <!-- Users List -->
          <div class="users-list">
            ${renderUsersList(assigns.users)}
          </div>
        </div>
        ''';
    }
    
    /**
     * Helper to render users list
     */
    private function renderUsersList(users: Array<Dynamic>): String {
        var html = "";
        for (user in users) {
            html += '''
            <div class="user-card">
              <h3>${user.name}</h3>
              <p>Email: ${user.email}</p>
              <button phx-click="delete_user" phx-value-id="${user.id}">Delete</button>
            </div>
            ''';
        }
        return html;
    }
}