/**
 * Negative test: @:has_many expects the target schema to have the FK field pointing back to the source.
 *
 * Expected: compilation fails with an association validation error.
 */
@:schema("users")
class User {
	public var id:Int;

	@:has_many("posts")
	public var posts:Array<Post>;
}

@:schema("posts")
class Post {
	public var id:Int;
	// Missing: user_id / userId
}

class Main {
	static function main() {}
}
