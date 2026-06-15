import ecto.Changeset;

typedef User = {
	var name:String;
}

typedef UserParams = {
	?name:String
}

class Main {
	static function main() {}

	public static function dynamicStringRejected(user:User, params:UserParams, fieldName:String):Changeset<User, UserParams> {
		return new Changeset(user, params).validateRequired([fieldName]);
	}
}
