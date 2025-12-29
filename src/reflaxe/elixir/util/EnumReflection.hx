package reflaxe.elixir.util;

/**
 * EnumReflection
 *
 * WHY
 * - Haxe 5 tightened name resolution for `Type` when `haxe.macro.Type` is imported.
 * - In macro-heavy modules we often need the stdlib reflection helpers like `Type.enumConstructor`
 *   for debug strings and lightweight tags, but `Type` may resolve to the macro `Type` enum instead.
 *
 * WHAT
 * - A tiny wrapper around stdlib enum reflection helpers to avoid `Type` name collisions.
 *
 * HOW
 * - Call `EnumReflection.enumConstructor(value)` instead of `Type.enumConstructor(value)`.
 */
class EnumReflection {
    public static inline function enumConstructor(value: EnumValue): String {
        return Type.enumConstructor(value);
    }
}
