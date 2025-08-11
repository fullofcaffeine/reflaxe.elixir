package;

/**
 * Basic Ecto Schema test case
 * Tests @:schema annotation compilation
 */
@:schema("users")
class User {
	public var id: Int;
	public var name: String;
	public var email: String;
	public var age: Int;
	public var active: Bool = true;
	
	@:timestamps
	public var inserted_at: Dynamic;
	public var updated_at: Dynamic;
	
	@:has_many("posts", "Post")
	public var posts: Array<Dynamic>;
	
	@:belongs_to("organization", "Organization")
	public var organization: Dynamic;
	public var organization_id: Int;
}