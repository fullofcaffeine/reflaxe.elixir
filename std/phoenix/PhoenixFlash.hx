package phoenix;

import elixir.types.Atom;
import phoenix.types.Flash.FlashMap;

/**
 * PhoenixFlash
 *
 * WHAT
 * - Typed extern for `Phoenix.Flash` helpers commonly used in LiveView templates.
 *
 * WHY
 * - Avoid embedding raw Elixir atoms (e.g. `:info`) and module calls inside HXX template strings.
 * - Keep example apps "Haxe-first": all Phoenix calls are made through typed externs.
 *
 * HOW
 * - Uses `elixir.types.Atom` for keys so string literals compile to atoms when required.
 * - Returns `Null<String>` (Elixir `nil | binary`) for missing keys.
 */
@:native("Phoenix.Flash")
extern class PhoenixFlash {
    @:native("get")
    static function get(flash: FlashMap, key: Atom): Null<String>;
}

