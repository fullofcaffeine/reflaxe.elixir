package;

/**
 * Minimal schema for negative typed query validation
 */
@:schema("users")
class User {
    public var id: Int;
    public var name: String;
    public var email: String;
    public var age: Int;
}

