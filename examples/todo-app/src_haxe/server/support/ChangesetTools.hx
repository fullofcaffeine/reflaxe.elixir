package server.support;

import ecto.ChangesetApi;

/**
 * App-local helper to call Ecto.Changeset.cast/3 without __elixir__ strings.
 */
@:keep
@:native("TodoApp.ChangesetTools")
class ChangesetTools {
    public static function castWithStringFields(struct:Dynamic, params:Dynamic, permitted:Array<String>):Dynamic {
        return ChangesetApi.castParams(struct, params, permitted);
    }
}
