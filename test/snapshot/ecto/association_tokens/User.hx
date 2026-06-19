package;

@:schema("users")
class User {
	@:primary_key
	public var id:Int;

	@:field({type: "string"})
	public var email:String;

	@:has_many("posts", "Post")
	public var posts:Array<Post>;
}
