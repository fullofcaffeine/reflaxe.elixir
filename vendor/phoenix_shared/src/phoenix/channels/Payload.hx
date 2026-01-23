package phoenix.channels;

#if js
import js.lib.Object;

/**
 * Payload (Phoenix Channels)
 *
 * WHAT
 * - Cross-target payload type used at the Channels boundary.
 *
 * WHY
 * - JS client payloads are plain JS objects with string keys.
 * - Elixir server payloads are BEAM terms (typically string-key maps decoded from JSON).
 *
 * HOW
 * - Resolves to `js.lib.Object` on JS.
 * - Resolves to `elixir.types.Term` on the Elixir target.
 */
typedef Payload = Object;

#else
import elixir.types.Term;

typedef Payload = Term;

#end

