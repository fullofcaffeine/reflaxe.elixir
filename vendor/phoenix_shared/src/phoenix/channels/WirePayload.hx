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

    public static inline function putInt(payload: Object, key: String, value: Int): Object {
        if (payload == null || key == null) return payload;
        Reflect.setField(cast payload, key, value);
        return payload;
    }

    public static inline function putBool(payload: Object, key: String, value: Bool): Object {
        if (payload == null || key == null) return payload;
        Reflect.setField(cast payload, key, value);
        return payload;
    }

    public static inline function putFloat(payload: Object, key: String, value: Float): Object {
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

    public static inline function getInt(payload: Object, key: String): Null<Int> {
        if (payload == null || key == null) return null;
        return cast js.Syntax.code(
            "((p,k)=>{var v=p[k]; if(v==null) return null; if(typeof v==='number') return (v|0); if(typeof v==='string'){var n=parseInt(v,10); return Number.isFinite(n)?(n|0):null;} return null;})({0},{1})",
            payload,
            key
        );
    }

    public static inline function getBool(payload: Object, key: String): Null<Bool> {
        if (payload == null || key == null) return null;
        return cast js.Syntax.code(
            "((p,k)=>{var v=p[k]; if(typeof v==='boolean') return v; return null;})({0},{1})",
            payload,
            key
        );
    }

    public static inline function getFloat(payload: Object, key: String): Null<Float> {
        if (payload == null || key == null) return null;
        return cast js.Syntax.code(
            "((p,k)=>{var v=p[k]; if(v==null) return null; if(typeof v==='number') return v; if(typeof v==='string'){var n=parseFloat(v); return Number.isFinite(n)?n:null;} return null;})({0},{1})",
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

    public static inline function putInt(payload: Term, key: String, value: Int): Term {
        return ElixirMap.put(payload, key, value);
    }

    public static inline function putBool(payload: Term, key: String, value: Bool): Term {
        return ElixirMap.put(payload, key, value);
    }

    public static inline function putFloat(payload: Term, key: String, value: Float): Term {
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

    public static function getInt(payload: Term, key: String): Null<Int> {
        var value = get(payload, key);
        if (value == null) return null;
        return Kernel.isInteger(value) ? cast value : null;
    }

    public static function getBool(payload: Term, key: String): Null<Bool> {
        var value = get(payload, key);
        if (value == null) return null;
        return Kernel.isBoolean(value) ? cast value : null;
    }

    public static function getFloat(payload: Term, key: String): Null<Float> {
        var value = get(payload, key);
        if (value == null) return null;
        if (Kernel.isFloat(value)) return cast value;
        if (Kernel.isInteger(value)) return cast untyped __elixir__('{0} * 1.0', value);
        return null;
    }
    #end
}
