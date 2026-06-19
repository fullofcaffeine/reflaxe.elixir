import ecto.Changeset;
import ecto.Field;

typedef User = {
	var age:Int;
	var score:Float;
}

typedef UserParams = {
	?age:Int,
	?score:Float
}

class Main {
	public static function preferredEctoNames(user:User, params:UserParams):Changeset<User, UserParams> {
		return new Changeset(user, params).validateNumber(Field.of((user:User) -> user.age), {
			greater_than_or_equal_to: 18,
			less_than_or_equal_to: 120
		}).validateNumber(Field.of((user:User) -> user.score), {
			greater_than: 0,
			less_than: 100,
			not_equal_to: 13
		});
	}

	public static function shorthandAliases(user:User, params:UserParams):Changeset<User, UserParams> {
		return new Changeset(user, params).validateNumber(Field.of((user:User) -> user.age), {min: 18, max: 120});
	}
}
