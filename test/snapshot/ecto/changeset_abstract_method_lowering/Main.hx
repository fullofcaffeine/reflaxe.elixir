import ecto.Changeset;
import elixir.types.Term;

typedef User = {
	var name:String;
	var role:String;
}

typedef UserParams = {
	?name:String,
	?role:String
}

/**
 * Guards abstract Changeset methods in the call shapes users actually write.
 */
class Main {
	static function main() {}

	public static function fluentChain(user:User, params:UserParams):Changeset<User, UserParams> {
		return new Changeset(user,
			params).validateRequired(["name"])
			.validateLength("name", {min: 2})
			.validateInclusion("role", [term("admin"), term("user")])
			.validateExclusion("role", [term("blocked")]);
	}

	public static function directReturn(user:User, params:UserParams):Changeset<User, UserParams> {
		var changeset = new Changeset(user, params);
		return changeset.validateRequired(["name"]);
	}

	public static function sameVariableReassignment(user:User, params:UserParams):Changeset<User, UserParams> {
		var changeset = new Changeset(user, params);
		changeset = changeset.validateRequired(["name"]);
		changeset = changeset.validateLength("name", {min: 2});
		changeset = changeset.validateInclusion("role", [term("admin"), term("user")]);
		changeset = changeset.validateExclusion("role", [term("blocked")]);
		return changeset;
	}

	static inline function term(value:String):Term {
		return cast value;
	}
}
