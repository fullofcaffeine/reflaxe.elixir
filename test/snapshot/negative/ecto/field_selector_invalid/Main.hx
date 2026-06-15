import ecto.Field;

class User {
	public var email:String;

	public function new() {}
}

class Main {
	static function main() {
		// Intentionally invalid: User has `email`, not `emali`.
		var field = Field.of((user:User) -> user.emali);
		untyped __elixir__('IO.inspect({0})', field);
	}
}
