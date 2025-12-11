package server.support;

import ecto.Changeset;

/**
 * Minimal app-local helpers around Ecto.Changeset.
 *
 * WHAT
 * - Provide cast_with_string_fields/3 expected by generated code.
 *
 * WHY
 * - Playwright flows call create_todo, which currently references
 *   TodoApp.ChangesetTools.cast_with_string_fields/3. Without this
 *   module, event handlers crash at runtime.
 *
 * HOW
 * - Delegate directly to Ecto.Changeset.cast/3; params may contain
 *   string keys so we rely on Ecto to normalize them.
 */
@:keep
@:native("TodoApp.ChangesetTools")
class ChangesetTools {
    public static function castWithStringFields(struct:Dynamic, params:Dynamic, permitted:Array<String>):Dynamic {
        // Delegate to shared helper (wraps Ecto.Changeset.cast/3)
        return ecto.ChangesetTools.castWithStringFields(struct, params, permitted);
    }
}
