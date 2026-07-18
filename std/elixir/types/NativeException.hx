package elixir.types;

#if (macro || reflaxe_runtime || elixir)
/**
 * Explicit typed view of an exception rescued from the native Elixir runtime.
 *
 * Use this only at target boundaries that must preserve an existing Elixir
 * exception term (for example, an ownership-safe transaction that rolls back
 * and then reports the original failure). Catching this type lowers directly
 * to `rescue error ->`; it does not apply Haxe thrown-value unwrapping.
 *
 * `@:native("")` deliberately gives this type-only rescue marker no target
 * module name. A rescued exception can be any native exception struct; this
 * declaration must not pretend that all such values belong to one module.
 * Ordinary structured values should use typed anonymous records instead.
 */
@:elixirNativeException
@:native("")
extern class NativeException {}
#end
