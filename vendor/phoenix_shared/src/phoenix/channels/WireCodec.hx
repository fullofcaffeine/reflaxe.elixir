package phoenix.channels;

import phoenix.channels.Payload;

/**
 * WireCodec (Phoenix Channels)
 *
 * WHAT
 * - Typed encoder/decoder for a whole payload object.
 *
 * WHY
 * - Channels sit at the client/server boundary; payloads are untyped on the wire.
 * - A `WireCodec<T>` makes it easy to keep a single source of truth for
 *   how a typed Haxe value is represented in a JSON-ish payload.
 *
 * HOW
 * - `encode(value)` produces a wire payload (`js.lib.Object` on JS, `Term` on Elixir).
 * - `decode(payload)` validates and returns `T`, or `null` if the payload is not compatible.
 */
typedef WireCodec<T> = {
    var encode: T -> Payload;
    var decode: Payload -> Null<T>;
}

