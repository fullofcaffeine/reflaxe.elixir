package;

import ecto.SchemaStruct;

@:native("Example.User")
@:schema("users")
class User {
	@:primary_key
	public var id:Int;

	@:field({type: "string", nullable: false})
	public var email:String;
}

class Main {
	static function acceptUser(user:User):Void {}

	static function main():Void {
		var user:User = SchemaStruct.empty(User);
		acceptUser(user);
	}
}
