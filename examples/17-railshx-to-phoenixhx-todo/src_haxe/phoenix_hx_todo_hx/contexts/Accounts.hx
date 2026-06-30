package phoenix_hx_todo_hx.contexts;

import StringTools;
import ecto.Changeset;
import ecto.SchemaStruct;
import ecto.TypedQuery;
import elixir.Enum;
import elixir.types.Term;
import haxe.functional.Result;
import phoenix_hx_todo_hx.data.User;
import phoenix_hx_todo_hx.infrastructure.Repo;

using reflaxe.elixir.macros.TypedQueryLambda;

/**
 * Accounts context for the demo session flow.
 *
 * WHAT
 * - Find-or-create users by email and expose the current user lookup used by LiveView.
 *
 * WHY
 * - Phoenix apps usually keep authentication/session decisions outside LiveViews.
 *   This mirrors that boundary without emulating Devise or Rails controllers.
 */
class Accounts {
	public static function normalizeEmail(email:String):String {
		return StringTools.trim(email).toLowerCase();
	}

	public static function normalizeName(name:String):String {
		return StringTools.trim(name);
	}

	public static function getUser(id:Int):Null<User> {
		return Repo.get(User, id);
	}

	public static function getUserByEmail(email:String):Null<User> {
		var normalizedEmail = normalizeEmail(email);
		var query = TypedQuery.from(User).where(user -> user.email == normalizedEmail);
		var users:Array<User> = Repo.all(query);
		return Enum.at(users, 0);
	}

	public static function getOrCreateDemoUser(name:String, email:String):Result<User, Changeset<User, Term>> {
		var normalizedName = normalizeName(name);
		var normalizedEmail = normalizeEmail(email);
		var existing = getUserByEmail(normalizedEmail);
		if (existing != null)
			return Ok(existing);

		var data = SchemaStruct.empty(User);
		var params:Term = {name: normalizedName, email: normalizedEmail};
		return Repo.insert(User.changeset(data, params));
	}
}
