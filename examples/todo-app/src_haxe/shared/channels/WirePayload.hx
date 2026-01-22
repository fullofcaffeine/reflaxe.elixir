package shared.channels;

#if js
import js.lib.Object;
#else
import elixir.ElixirMap;
import elixir.Atom;
import elixir.Kernel;
import elixir.types.Term;
#end

/**
 * WirePayload
 *
 * WHAT
 * - Cross-target helpers for reading JSON-ish payloads used by Channels.
 *
 * WHY
 * - Client payloads are plain JS objects with string keys.
 * - Server payloads arrive as string-key maps (decoded from JSON); internal code may use atom keys.
 * - We need safe key reading without atom leaks (no `String.to_atom/1` on untrusted keys).
 */
class WirePayload {
    #if js
    public static inline function getString(payload: Object, key: String): Null<String> {
        if (payload == null || key == null) return null;
        return cast js.Syntax.code(
            "((p,k)=>{var v=p[k]; return v==null?null:String(v);})({0},{1})",
            payload,
            key
        );
    }
    #else
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
