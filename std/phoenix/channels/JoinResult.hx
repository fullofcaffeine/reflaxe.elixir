package phoenix.channels;

#if (macro || reflaxe_runtime)
import elixir.types.Term;
import haxe.functional.Result;

/**
 * JoinResult (Phoenix Channels)
 *
 * WHAT
 * - Convenience alias for Channel `join/3` results.
 *
 * WHY
 * - `join/3` is fundamentally an `{:ok, socket}` / `{:error, reason}` contract.
 * - Using `haxe.functional.Result` keeps this boundary typed while compiling to the canonical tuples.
 *
 * HOW
 * - `Ok(socket)` → `{:ok, socket}`
 * - `Error(reason)` → `{:error, reason}`
 */
typedef JoinResult<TSocket> = Result<TSocket, Term>;
#end
