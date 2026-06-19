package;

@:schema("posts")
class Post {
	@:primary_key
	public var id:Int;

	@:field({type: "string"})
	public var title:String;

	@:field({type: "integer"})
	public var userId:Int;

	@:belongs_to("user", "User")
	public var user:User;
}
