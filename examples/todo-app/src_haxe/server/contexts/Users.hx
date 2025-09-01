package contexts;

/**
 * Complete user management context with Ecto integration
 * Demonstrates schemas, changesets, queries, and business logic
 */

@:schema("users")
class User {
    @:primary_key
    public var id: Int;
    
    @:field({type: "string", nullable: false})
    public var name: String;
    
    @:field({type: "string", nullable: false})
    public var email: String;
    
    @:field({type: "integer"})
    public var age: Int;
    
    @:field({type: "boolean", defaultValue: true})
    public var active: Bool;
    
    @:timestamps
    public var insertedAt: String;
    public var updatedAt: String;
    
    @:has_many("posts", "Post", "user_id")
    public var posts: Array<Post>;
}

@:changeset
class UserChangeset {
    @:validate_required(["name", "email"])
    @:validate_format("email", "email_regex")
    @:validate_length("name", {min: 2, max: 100})
    @:validate_number("age", {greater_than: 0, less_than: 150})
    public static function changeset(user: User, attrs: Dynamic): Dynamic {
        // Changeset pipeline will be generated
        return null;
    }
}

class Users {
    /**
     * Get all users with optional filtering
     */
    public static function list_users(?filter: UserFilter): Array<User> {
        // Use __elixir__ to call Ecto directly until @:query annotation is implemented
        return untyped __elixir__("TodoApp.Repo.all(User)");
    }
    
    /**
     * Create changeset for user (required by LiveView example)
     */
    public static function change_user(?user: User): Dynamic {
        // Would create Ecto changeset - simplified for compilation
        return {valid: true};
    }
    
    /**
     * Main function for compilation testing
     */
    public static function main(): Void {
        trace("Users context with User schema compiled successfully!");
    }
    
    /**
     * Get user by ID with error handling
     */
    public static function get_user(id: Int): User {
        // Use __elixir__ to call Ecto directly  
        return untyped __elixir__("TodoApp.Repo.get!(User, {0})", id);
    }
    
    /**
     * Get user by ID, returns null if not found
     */
    public static function get_user_safe(id: Int): Null<User> {
        // Use __elixir__ to call Ecto directly
        return untyped __elixir__("TodoApp.Repo.get(User, {0})", id);
    }
    
    /**
     * Create a new user
     */
    public static function create_user(attrs: Dynamic): {status: String, ?user: User, ?changeset: Dynamic} {
        // Create changeset and insert using Ecto
        var result = untyped __elixir__("
            changeset = User.changeset(%User{}, {0})
            case TodoApp.Repo.insert(changeset) do
                {:ok, user} -> %{status: \"ok\", user: user}
                {:error, changeset} -> %{status: \"error\", changeset: changeset}
            end
        ", attrs);
        return result;
    }
    
    /**
     * Update existing user
     */
    public static function update_user(user: User, attrs: Dynamic): {status: String, ?user: User, ?changeset: Dynamic} {
        // Update user using Ecto
        var result = untyped __elixir__("
            changeset = User.changeset({0}, {1})
            case TodoApp.Repo.update(changeset) do
                {:ok, user} -> %{status: \"ok\", user: user}
                {:error, changeset} -> %{status: \"error\", changeset: changeset}
            end
        ", user, attrs);
        return result;
    }
    
    /**
     * Delete user (hard delete from database)
     */
    public static function delete_user(user: User): {status: String, ?user: User} {
        // Delete user using Ecto
        var result = untyped __elixir__("
            case TodoApp.Repo.delete({0}) do
                {:ok, user} -> %{status: \"ok\", user: user}
                {:error, _} -> %{status: \"error\"}
            end
        ", user);
        return result;
    }
    
    /**
     * Search users by name or email
     */
    public static function search_users(term: String): Array<User> {
        // Query DSL implementation will be handled by future @:query annotation
        return [];
    }
    
    /**
     * Get users with their posts (preload association)
     */
    static function users_with_posts(): Array<User> {
        // Query DSL implementation will be handled by future @:query annotation
        return [];
    }
    
    /**
     * Get user statistics
     */
    public static function user_stats(): UserStats {
        // Query DSL implementation will be handled by future @:query annotation
        return {total: 0, active: 0, inactive: 0};
    }
}

// Supporting types
typedef UserFilter = {
    ?active: Bool,
    ?minAge: Int,
    ?maxAge: Int
}

typedef UserStats = {
    total: Int,
    active: Int,
    inactive: Int
}

typedef Post = {
    id: Int,
    title: String,
    user_id: Int
}