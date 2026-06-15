import ecto.Changeset;
import ecto.Field;
import elixir.types.Term;

typedef User = {
	var name:String;
	var email:String;
	var age:Int;
	var role:String;
}

typedef UserParams = {
	?name:String,
	?email:String,
	?age:Int,
	?role:String
}

class Main {
	static function main() {}

	public static function typedTokens(user:User, params:UserParams):Changeset<User, UserParams> {
		return new Changeset(user, params).castFields([
			Field.of((user:User) -> user.name),
			Field.of((user:User) -> user.email),
			Field.of((user:User) -> user.age),
			Field.of((user:User) -> user.role)
		])
			.validateRequired([Field.of((user:User) -> user.name), Field.of((user:User) -> user.email)])
			.validateLength(Field.of((user:User) -> user.name),
				{
					min: 2,
					max: 80
				})
			.validateFormat(Field.of((user:User) -> user.email), ~/@/)
			.validateNumber(Field.of((user:User) -> user.age), {min: 18, max: 120})
			.validateInclusion(Field.of((user:User) -> user.role), [term("admin"), term("user")])
			.validateExclusion(Field.of((user:User) -> user.role), [term("blocked")]);
	}

	public static function literalCompatibility(user:User, params:UserParams):Changeset<User, UserParams> {
		return new Changeset(user, params).castFields(["name", "email"]).validateRequired(["name"]).validateLength("name", {min: 2});
	}

	static inline function term(value:String):Term {
		return cast value;
	}
}
