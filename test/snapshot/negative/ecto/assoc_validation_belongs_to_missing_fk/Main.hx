/**
 * Negative test: @:belongs_to requires a local FK field (by default `<assoc>_id`).
 *
 * Expected: compilation fails with an association validation error.
 */

@:schema("users")
class User {
    public var id: Int;
    public var name: String;
}

@:schema("posts")
class Post {
    public var id: Int;

    @:belongs_to("user")
    public var user: User;

    // Missing: user_id / userId
}

class Main {
    static function main() {}
}

