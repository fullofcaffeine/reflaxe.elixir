package elixir.types;

#if (macro || reflaxe_runtime || elixir)
/**
 * Opaque reason caught from a synchronous native BEAM exit.
 *
 * `catch (_:NativeExit)` lowers to `catch :exit, _ ->`, without rescuing
 * exceptions or catching native throws. Use it around target calls such as
 * GenServer.call that exit when their server is unavailable. Keep it as the
 * only catch clause; nest a separate try to handle exceptions as well.
 *
 * Reasons can contain request data. Discard them when reporting a generic
 * failure; never assume they are safe log messages. This marker does not
 * intercept asynchronous exit signals or make an untrappable kill recoverable.
 * It has no target module because a native exit reason can be any BEAM term.
 */
@:elixirNativeExit
@:native("")
extern class NativeExit {}
#end
