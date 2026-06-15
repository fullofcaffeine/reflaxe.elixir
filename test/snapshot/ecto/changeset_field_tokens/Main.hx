import ecto.Field;

class User {
	public var name:String;
	public var email:String;
	public var age:Int;
	public var role:String;
	public var lastLoginAt:String;

	public function new() {}
}

class Main {
	static function main() {
		var fields = fieldsForChangeset();
		var email = emailField();
		var lastLoginAt = lastLoginAtField();
		untyped __elixir__('IO.inspect(%{fields: {0}, email: {1}, last_login_at: {2}})', fields, email, lastLoginAt);
	}

	static function fieldsForChangeset():Array<String> {
		return [
			Field.of((user:User) -> user.name),
			Field.of((user:User) -> user.email),
			Field.of((user:User) -> user.age),
			Field.of((user:User) -> user.role),
			Field.of((user:User) -> user.lastLoginAt)
		];
	}

	static function emailField():String {
		return Field.of((user:User) -> user.email);
	}

	static function lastLoginAtField():String {
		return Field.of((user:User) -> user.lastLoginAt);
	}
}
