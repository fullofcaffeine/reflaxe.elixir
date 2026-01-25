package phoenix.channels;

import phoenix.channels.Payload;
import phoenix.channels.WireCodec;
import phoenix.channels.WireField;
import phoenix.channels.WirePayload;

/**
 * WireCodecs (Phoenix Channels)
 *
 * WHAT
 * - Small, composable helpers to build `WireCodec<T>` values from `WireField<T>` definitions.
 *
 * WHY
 * - Channel payloads are untyped maps/objects. Protocol modules should stay focused on
 *   event names + business semantics, not repetitive map plumbing.
 * - A shared codec builder keeps client/server wire contracts consistent.
 *
 * HOW
 * - `object1/object2` build codecs for payload objects with required fields.
 * - Decoders return `null` if any required field is missing or invalid.
 */
class WireCodecs {
    public static inline function object1<A, T>(
        fieldA: WireField<A>,
        from: A -> T,
        getA: T -> A
    ): WireCodec<T> {
        return {
            encode: function(value: T): Payload {
                var payload = WirePayload.empty();
                payload = fieldA.put(payload, getA(value));
                return payload;
            },
            decode: function(payload: Payload): Null<T> {
                var a = fieldA.get(payload);
                return a != null ? from(a) : null;
            }
        };
    }

    public static inline function object2<A, B, T>(
        fieldA: WireField<A>,
        fieldB: WireField<B>,
        from: (A, B) -> T,
        getA: T -> A,
        getB: T -> B
    ): WireCodec<T> {
        return {
            encode: function(value: T): Payload {
                var payload = WirePayload.empty();
                payload = fieldA.put(payload, getA(value));
                payload = fieldB.put(payload, getB(value));
                return payload;
            },
            decode: function(payload: Payload): Null<T> {
                var a = fieldA.get(payload);
                if (a == null) return null;
                var b = fieldB.get(payload);
                if (b == null) return null;
                return from(a, b);
            }
        };
    }
}

