package phoenix.channels;

#if js
import js.lib.Object;
#else
import elixir.Atom;
import elixir.ElixirMap;
import elixir.Kernel;
import elixir.types.Term;
#end

/**
 * WirePayload (Phoenix Channels)
 *
 * WHAT
 * - Cross-target helpers for reading/writing JSON-ish payloads used at the Channels boundary.
 *
 * WHY
 * - Client payloads are plain JS objects with string keys.
 * - Server payloads arrive as string-key maps (decoded from JSON), but internal code may also
 *   use atom keys depending on how a map was constructed.
 * - We need safe key reading without atom leaks (no `String.to_atom/1` on untrusted keys).
 *
 * HOW
 * - JS: index into the object by key.
 * - Elixir: try string key first; then fall back to an existing atom key (`String.to_existing_atom/1`).
 */
#if !js
@:native("Phoenix.Channels.WirePayload")
#end
class WirePayload {
    #if js
    public static inline function empty(): Object {
        return cast {};
    }

    public static inline function putString(payload: Object, key: String, value: String): Object {
        if (payload == null || key == null) return payload;
        Reflect.setField(cast payload, key, value);
        return payload;
    }

    public static inline function getString(payload: Object, key: String): Null<String> {
        if (payload == null || key == null) return null;
        return cast js.Syntax.code(
            "((p,k)=>{var v=p[k]; return v==null?null:String(v);})({0},{1})",
            payload,
            key
        );
    }
    #else
    public static inline function empty(): Term {
        return cast {};
    }

    public static inline function putString(payload: Term, key: String, value: String): Term {
        return ElixirMap.put(payload, key, value);
    }

    public static function get(payload: Term, key: String): Term {
        if (payload == null || key == null) return null;

        var value = ElixirMap.get(payload, key);
        if (value != null) return value;

        var atom = Atom.existingOrNull(key);
        return atom != null ? ElixirMap.get(payload, atom) : null;
    }

    public static function getString(payload: Term, key: String): Null<String> {
        var value = get(payload, key);
        return value != null ? Kernel.toString(value) : null;
    }
    #end
}
