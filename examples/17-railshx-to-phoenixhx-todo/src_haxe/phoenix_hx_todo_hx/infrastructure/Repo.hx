package phoenix_hx_todo_hx.infrastructure;

import ecto.Changeset;
import ecto.DatabaseAdapter.*;
import ecto.Query.EctoQuery;
import haxe.functional.Result;

/**
 * PhoenixHxTodo.Repo
 *
 * WHAT
 * - Typed Ecto repository for the RailsHx-to-PhoenixHx todo port.
 *
 * WHY
 * - RailsHx uses ActiveRecord directly from the Rails-shaped app. This Phoenix port
 *   keeps persistence in the Phoenix/Ecto boundary: schemas + contexts + Repo.
 *
 * HOW
 * - `@:repo` emits a standard `Ecto.Repo` module and companion Postgrex types module.
 */
@:native("PhoenixHxTodo.Repo")
@:repo({
	adapter: Postgres,
	json: Jason,
	extensions: [],
	poolSize: 10
})
extern class Repo {
	@:overload(function<T>(query:EctoQuery<T>):Array<T> {})
	@:overload(function<T>(query:ecto.TypedQuery.TypedQuery<T>):Array<T> {})
	public static function all<T>(queryable:Class<T>):Array<T>;

	public static function get<T>(queryable:Class<T>, id:Int):Null<T>;

	public static function insert<T, P>(changeset:Changeset<T, P>):Result<T, Changeset<T, P>>;

	public static function update<T, P>(changeset:Changeset<T, P>):Result<T, Changeset<T, P>>;

	public static function delete<T>(struct:T):Result<T, Changeset<T, {}>>;
}
