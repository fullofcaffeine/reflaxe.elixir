package;

using ArrayTools;
/**
 * Repository Pattern Integration test
 * Tests Repo.all/insert/update/delete compilation with type safety
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
}

@:changeset
class UserChangeset {
    @:validate_required(["name", "email"])
    @:validate_format("email", "email_regex")
    @:validate_length("name", {min: 2, max: 100})
    public static function changeset(user: User, attrs: Dynamic): Dynamic {
        return null; // Changeset will be generated
    }
}

class Main {
    /**
     * Main function for compilation testing
     */
    public static function main(): Void {
        trace("Repository pattern compilation test complete!");
    }
}

class UserRepository {
    /**
     * List all users - compiles to Repo.all(User)
     */
    public static function getAllUsers(): Array<User> {
        return untyped Repo.all(User);
    }
    
    /**
     * Get user by ID - compiles to Repo.get!(User, id)
     */
    public static function getUser(id: Int): User {
        return untyped Repo.get(User, id);
    }
    
    /**
     * Get user by ID (raises if not found) - compiles to Repo.get!(User, id)
     */
    public static function getUserBang(id: Int): User {
        return untyped Repo.getBang(User, id);
    }
    
    /**
     * Create user - compiles to Repo.insert(changeset) with error tuple handling
     */
    public static function createUser(attrs: Dynamic): Dynamic {
        var changeset = UserChangeset.changeset(null, attrs);
        return untyped Repo.insert(changeset);
    }
    
    /**
     * Update user - compiles to Repo.update(changeset) with error tuple handling
     */
    public static function updateUser(user: User, attrs: Dynamic): Dynamic {
        var changeset = UserChangeset.changeset(user, attrs);
        return untyped Repo.update(changeset);
    }
    
    /**
     * Delete user - compiles to Repo.delete(user) with error tuple handling
     */
    public static function deleteUser(user: User): Dynamic {
        return untyped Repo.delete(user);
    }
    
    /**
     * Preload associations - compiles to Repo.preload(user, [:posts])
     */
    public static function preloadPosts(user: User): User {
        return untyped Repo.preload(user, ["posts"]);
    }
    
    /**
     * Count users - compiles to Repo.aggregate(User, :count)
     */
    public static function countUsers(): Int {
        return untyped Repo.aggregate(User, "count");
    }
    
    /**
     * Get first user - compiles to Repo.one(query)
     */
    public static function getFirstUser(): User {
        return untyped Repo.one(User);
    }
}

// External Repo module definition (would normally be an extern)
extern class Repo {
    public static function all(schema: Dynamic): Array<Dynamic>;
    public static function get(schema: Dynamic, id: Dynamic): Dynamic;
    @:native("get!")
    public static function getBang(schema: Dynamic, id: Dynamic): Dynamic;
    public static function insert(changeset: Dynamic): Dynamic;
    public static function update(changeset: Dynamic): Dynamic;
    public static function delete(struct: Dynamic): Dynamic;
    public static function preload(struct: Dynamic, associations: Array<String>): Dynamic;
    public static function aggregate(schema: Dynamic, operation: String): Dynamic;
    public static function one(query: Dynamic): Dynamic;
}