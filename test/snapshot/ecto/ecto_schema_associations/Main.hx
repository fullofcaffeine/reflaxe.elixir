/**
 * Ecto schema association emission (typed) snapshot
 *
 * Covers:
 * - Association module inference from field types (no explicit module string)
 * - many_to_many join-through option parsing
 * - Class-level @:timestamps emission
 */
@:schema("organizations")
class Organization {
	public function new() {}

	public var id:Int;
	public var name:String;
}

@:schema("tags")
class Tag {
	public function new() {}

	public var id:Int;
	public var name:String;
}

@:schema("posts")
@:timestamps
class Post {
	public function new() {}

	public var id:Int;
	public var title:String;

	@:belongs_to("organization")
	public var organization:Organization;
	public var organization_id:Int;

	@:many_to_many("tags")
	public var tags:Array<Tag>;
}

class Main {
	public static function main() {}
}
