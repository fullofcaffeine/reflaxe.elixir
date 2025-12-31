package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.TypeTools;

/**
 * TypeUtils
 *
 * WHAT
 * - Small helpers for reasoning about Haxe macro `Type` values in the Elixir AST pipeline.
 *
 * WHY
 * - Some compile-time marker abstracts (notably `elixir.types.Atom`) affect how literals must be
 *   printed in Elixir, but Haxe often represents those values as *other* abstracts layered over
 *   `Atom` (e.g. enum abstracts like `TimeUnit(Atom)`).
 * - If we only detect `elixir.types.Atom` directly, enum-abstract atoms are emitted as strings
 *   (e.g. `"second"`) which breaks Elixir APIs expecting atoms (e.g. `DateTime.truncate/2` wants
 *   `:second`).
 *
 * HOW
 * - Follow typedefs/monos and walk abstract-underlying-type chains until we either find
 *   `elixir.types.Atom` or hit a non-abstract terminal type.
 *
 * EXAMPLES
 * - Haxe:
 *     enum abstract TimePrecision(elixir.types.Atom) from elixir.types.Atom {
 *       var Second = "second";
 *     }
 *   Elixir:
 *     DateTime.truncate(dt, :second)
 */
@:nullSafety(Off)
class TypeUtils {
    public static function isElixirAtomType(t: Null<Type>): Bool {
        return isElixirAtomTypeInner(t, 0);
    }

    static function isElixirAtomTypeInner(t: Null<Type>, depth: Int): Bool {
        if (t == null) return false;
        if (depth > 20) return false;

        var followed = TypeTools.follow(t);

        return switch (followed) {
            case TAbstract(ref, _):
                var at = ref.get();
                if (at.pack.join(".") == "elixir.types" && at.name == "Atom") {
                    true;
                } else {
                    isElixirAtomTypeInner(at.type, depth + 1);
                }
            case TType(td, _):
                isElixirAtomTypeInner(td.get().type, depth + 1);
            case TLazy(f):
                isElixirAtomTypeInner(f(), depth + 1);
            default:
                false;
        }
    }
}

#end
