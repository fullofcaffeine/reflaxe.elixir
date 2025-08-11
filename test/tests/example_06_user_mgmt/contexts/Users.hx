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
        // Query DSL implementation will be handled by future @:query annotation
        return [];
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
        // Would integrate with Repo.get!
        return null;
    }
    
    /**
     * Get user by ID, returns null if not found
     */
    public static function get_user_safe(id: Int): Null<User> {
        // Would integrate with Repo.get
        return null;
    }
    
    /**
     * Create a new user
     */
    public static function create_user(attrs: Dynamic): {status: String, ?user: User, ?changeset: Dynamic} {
        var changeset = UserChangeset.changeset(null, attrs);
        
        if (changeset != null) {
            // Would call Repo.insert
            return {status: "ok", user: null};
        } else {
            return {status: "error", changeset: changeset};
        }
    }
    
    /**
     * Update existing user
     */
    public static function update_user(user: User, attrs: Dynamic): {status: String, ?user: User, ?changeset: Dynamic} {
        var changeset = UserChangeset.changeset(user, attrs);
        
        if (changeset != null) {
            // Would call Repo.update
            return {status: "ok", user: user};
        } else {
            return {status: "error", changeset: changeset};
        }
    }
    
    /**
     * Delete user (soft delete by setting active: false)
     */
    public static function delete_user(user: User): {status: String, ?user: User} {
        return update_user(user, {active: false});
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