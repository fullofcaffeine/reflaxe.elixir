package phoenix.channels;

import phoenix.channels.Payload;
import phoenix.channels.WireCodec;
import phoenix.channels.WireField;
import phoenix.channels.WirePayload;

/**
 * WireFields (Phoenix Channels)
 *
 * WHAT
 * - Constructors for common typed `WireField<T>` shapes.
 *
 * WHY
 * - Keeps protocol modules small and consistent across JS + Elixir targets.
 * - Centralizes key read/write behavior so boundary rules (like safe map access) stay uniform.
 *
 * HOW
 * - Each constructor captures the string key and delegates to `WirePayload.getX/putX`.
 */
class WireFields {
    public static inline function codec<T>(key: String, codec: WireCodec<T>): WireField<T> {
        return {
            key: key,
            put: function(payload: Payload, value: T): Payload return WirePayload.putPayload(payload, key, codec.encode(value)),
            get: function(payload: Payload): Null<T> {
                var raw = WirePayload.getPayload(payload, key);
                return raw != null ? codec.decode(raw) : null;
            }
        };
    }

    public static inline function payload(key: String): WireField<Payload> {
        return {
            key: key,
            put: function(payload: Payload, value: Payload): Payload return WirePayload.putPayload(payload, key, value),
            get: function(payload: Payload): Null<Payload> return WirePayload.getPayload(payload, key)
        };
    }

    public static inline function string(key: String): WireField<String> {
        return {
            key: key,
            put: function(payload: Payload, value: String): Payload return WirePayload.putString(payload, key, value),
            get: function(payload: Payload): Null<String> return WirePayload.getString(payload, key)
        };
    }

    public static inline function int(key: String): WireField<Int> {
        return {
            key: key,
            put: function(payload: Payload, value: Int): Payload return WirePayload.putInt(payload, key, value),
            get: function(payload: Payload): Null<Int> return WirePayload.getInt(payload, key)
        };
    }

    public static inline function bool(key: String): WireField<Bool> {
        return {
            key: key,
            put: function(payload: Payload, value: Bool): Payload return WirePayload.putBool(payload, key, value),
            get: function(payload: Payload): Null<Bool> return WirePayload.getBool(payload, key)
        };
    }

    public static inline function float(key: String): WireField<Float> {
        return {
            key: key,
            put: function(payload: Payload, value: Float): Payload return WirePayload.putFloat(payload, key, value),
            get: function(payload: Payload): Null<Float> return WirePayload.getFloat(payload, key)
        };
    }

    public static inline function stringArray(key: String): WireField<Array<String>> {
        return {
            key: key,
            put: function(payload: Payload, value: Array<String>): Payload return WirePayload.putStringArray(payload, key, value),
            get: function(payload: Payload): Null<Array<String>> return WirePayload.getStringArray(payload, key)
        };
    }

    public static inline function intArray(key: String): WireField<Array<Int>> {
        return {
            key: key,
            put: function(payload: Payload, value: Array<Int>): Payload return WirePayload.putIntArray(payload, key, value),
            get: function(payload: Payload): Null<Array<Int>> return WirePayload.getIntArray(payload, key)
        };
    }
}
