package elixir.types;

#if (macro || reflaxe_runtime || elixir)
/**
 * Explicit typed view of an exception rescued from the native Elixir runtime.
 *
 * Use this only at target boundaries that must preserve an existing Elixir
 * exception term (for example, an ownership-safe transaction that rolls back
 * and then reports the original failure). Catching this type lowers directly
 * to `rescue error ->`; it does not apply Haxe thrown-value unwrapping.
 */
@:elixirNativeException
@:native("")
extern class NativeException {}
#end
