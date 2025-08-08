package fixtures;

/**
 * Test struct class definitions for validation
 */

// Simple struct with @:struct metadata
@:struct
class User {
    public var id: Int;
    public var name: String;
    public var email: String;
    public var active: Bool = true;
    
    public function new(id: Int, name: String, email: String) {
        this.id = id;
        this.name = name;
        this.email = email;
    }
}

// Struct with nullable fields
@:struct
class Product {
    public var id: Int;
    public var title: String;
    public var description: Null<String>;
    public var price: Float;
    public var inStock: Bool = true;
    
    public function new(id: Int, title: String, price: Float) {
        this.id = id;
        this.title = title;
        this.price = price;
    }
}

// Struct with final/immutable fields
@:struct
class Config {
    public final key: String;
    public final value: String;
    public final locked: Bool = false;
    
    public function new(key: String, value: String) {
        this.key = key;
        this.value = value;
    }
}

// Regular class (not a struct) - should compile to module with functions
class UserService {
    public static function findById(id: Int): Null<User> {
        // Implementation would go here
        return null;
    }
    
    public static function createUser(name: String, email: String): User {
        return new User(1, name, email);
    }
    
    public function updateUser(user: User, name: String): User {
        // In Elixir, this would return a new struct
        return user;
    }
}

// Phoenix-style context class
class Accounts {
    public static function getUser(id: Int): Null<User> {
        return null;
    }
    
    public static function listUsers(): Array<User> {
        return [];
    }
    
    public static function updateUser(user: User, attrs: Dynamic): User {
        return user;
    }
}

// Ecto-style schema class
@:struct
@:schema("users")
class UserSchema {
    public var id: Int;
    public var name: String;
    public var email: String;
    public var insertedAt: Date;
    public var updatedAt: Date;
    
    public function changeset(attrs: Dynamic): Dynamic {
        // Would generate Ecto changeset
        return null;
    }
}