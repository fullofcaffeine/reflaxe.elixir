import ecto.Changeset;

typedef UserParams = {
	var name:String;
	var email:String;
}

@:schema("users")
@:changeset(["name", "email"], ["name", "email"])
class User {
	public function new() {}

	@:field public var id:Int;
	@:field public var name:String;
	@:field public var email:String;
}

@:schema("users_explicit")
@:changeset(["name", "email"], ["name", "email"])
class UserExplicit {
	public function new() {}

	@:field public var id:Int;
	@:field public var name:String;
	@:field public var email:String;

	// Compatibility path: explicit declaration remains supported.
	extern public static function changeset(record:UserExplicit, attrs:UserParams):Changeset<UserExplicit, UserParams>;
}

class Main {
	static function main() {
		var params:UserParams = {name: "Ada", email: "ada@example.com"};
		var autoChangeset:Changeset<User, UserParams> = User.changeset(new User(), params);
		var explicitChangeset:Changeset<UserExplicit, UserParams> = UserExplicit.changeset(new UserExplicit(), params);
		trace(autoChangeset);
		trace(explicitChangeset);
	}
}
