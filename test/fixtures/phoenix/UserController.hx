package phoenix;

/**
 * Example Phoenix Controller
 * Tests controller generation with proper Phoenix patterns
 */
class UserController extends Phoenix.Controller {
    
    /**
     * List all users - GET /users
     */
    public function index(conn: Dynamic, params: Dynamic): Dynamic {
        var users = UserContext.list_users();
        return Phoenix.Controller.render(conn, "index.html", {users: users});
    }
    
    /**
     * Show user creation form - GET /users/new
     */
    public function new(conn: Dynamic, params: Dynamic): Dynamic {
        var changeset = User.changeset(new User(), {});
        return Phoenix.Controller.render(conn, "new.html", {changeset: changeset});
    }
    
    /**
     * Create a new user - POST /users
     */
    public function create(conn: Dynamic, params: Dynamic): Dynamic {
        switch (UserContext.create_user(params.user)) {
            case {ok: user}:
                Phoenix.Controller.put_flash(conn, "info", "User created successfully");
                return Phoenix.Controller.redirect(conn, Phoenix.Router.path(conn, "user", user.id));
                
            case {error: changeset}:
                return Phoenix.Controller.render(conn, "new.html", {changeset: changeset});
        }
    }
    
    /**
     * Show single user - GET /users/:id
     */
    public function show(conn: Dynamic, params: Dynamic): Dynamic {
        try {
            var user = UserContext.get_user!(params.id);
            return Phoenix.Controller.render(conn, "show.html", {user: user});
        } catch (e: Dynamic) {
            Phoenix.Controller.put_flash(conn, "error", "User not found");
            return Phoenix.Controller.redirect(conn, Phoenix.Router.path(conn, "users"));
        }
    }
    
    /**
     * Show user edit form - GET /users/:id/edit
     */
    public function edit(conn: Dynamic, params: Dynamic): Dynamic {
        var user = UserContext.get_user!(params.id);
        var changeset = User.changeset(user, {});
        return Phoenix.Controller.render(conn, "edit.html", {user: user, changeset: changeset});
    }
    
    /**
     * Update a user - PUT/PATCH /users/:id
     */
    public function update(conn: Dynamic, params: Dynamic): Dynamic {
        var user = UserContext.get_user!(params.id);
        
        switch (UserContext.update_user(user, params.user)) {
            case {ok: user}:
                Phoenix.Controller.put_flash(conn, "info", "User updated successfully");
                return Phoenix.Controller.redirect(conn, Phoenix.Router.path(conn, "user", user.id));
                
            case {error: changeset}:
                return Phoenix.Controller.render(conn, "edit.html", {user: user, changeset: changeset});
        }
    }
    
    /**
     * Delete a user - DELETE /users/:id
     */
    public function delete(conn: Dynamic, params: Dynamic): Dynamic {
        var user = UserContext.get_user!(params.id);
        
        switch (UserContext.delete_user(user)) {
            case {ok: _}:
                Phoenix.Controller.put_flash(conn, "info", "User deleted successfully");
                return Phoenix.Controller.redirect(conn, Phoenix.Router.path(conn, "users"));
                
            case {error: _}:
                Phoenix.Controller.put_flash(conn, "error", "Error deleting user");
                return Phoenix.Controller.redirect(conn, Phoenix.Router.path(conn, "user", user.id));
        }
    }
}