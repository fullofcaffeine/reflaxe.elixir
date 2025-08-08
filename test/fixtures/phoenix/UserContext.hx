package phoenix;

/**
 * Example Phoenix Context with @:context annotation
 * Tests context generation and Ecto integration
 */
@:context("Users")
class UserContext {
    
    /**
     * List all users with optional filters
     */
    public static function list_users(?filters: Dynamic): Array<User> {
        // Query using Ecto.Query (would compile to proper Elixir query)
        return Ecto.Repo.all(Ecto.Query.from(User));
    }
    
    /**
     * Get user by ID
     */
    public static function get_user(id: Int): Null<User> {
        return Ecto.Repo.get(User, id);
    }
    
    /**
     * Get user by ID, raise if not found
     */
    public static function get_user!(id: Int): User {
        return Ecto.Repo.get!(User, id);
    }
    
    /**
     * Create a new user with validation
     */
    public static function create_user(attrs: Dynamic): {ok: User} | {error: Dynamic} {
        var changeset = User.changeset(new User(), attrs);
        return Ecto.Repo.insert(changeset);
    }
    
    /**
     * Update an existing user
     */
    public static function update_user(user: User, attrs: Dynamic): {ok: User} | {error: Dynamic} {
        var changeset = User.changeset(user, attrs);
        return Ecto.Repo.update(changeset);
    }
    
    /**
     * Delete a user
     */
    public static function delete_user(user: User): {ok: User} | {error: Dynamic} {
        return Ecto.Repo.delete(user);
    }
    
    /**
     * Find users by email pattern
     */
    public static function find_users_by_email(pattern: String): Array<User> {
        var query = Ecto.Query.from(User);
        query = Ecto.Query.where(query, {email: {like: pattern}});
        return Ecto.Repo.all(query);
    }
}