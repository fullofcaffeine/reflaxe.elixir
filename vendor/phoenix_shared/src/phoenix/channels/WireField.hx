package phoenix.channels;

import phoenix.channels.Payload;

/**
 * WireField (Phoenix Channels)
 *
 * WHAT
 * - A typed description of a single string-key field inside a channel payload.
 *
 * WHY
 * - Channel payloads are maps/objects with string keys and JSON-ish values.
 * - Protocol definitions often repeat the same `WirePayload.getX/putX` calls for each key.
 * - This type packages those operations into a reusable, typed unit.
 *
 * HOW
 * - `key` is the canonical wire key (string, snake_case).
 * - `put(payload, value)` writes the value to the payload.
 * - `get(payload)` reads and validates the value from the payload.
 */
typedef WireField<T> = {
    var key: String;
    var put: (Payload, T) -> Payload;
    var get: Payload -> Null<T>;
}

