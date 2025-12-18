package reflaxe.elixir.generator;

import haxe.ds.StringMap;

/**
 * TemplateContext / TemplateValue
 *
 * WHAT
 * - A small, typed key/value store used by the project template engine.
 *
 * WHY
 * - Template keys are dynamic (arbitrary placeholders) but generator code should not
 *   expose untyped values in signatures. This keeps the generator predictable and refactor-safe.
 *
 * HOW
 * - `TemplateContext` stores `TemplateValue` entries in a `StringMap`.
 * - `TemplateEngine` consumes this context for placeholder replacement and simple control flow.
 */
class TemplateContext {
    final values: StringMap<TemplateValue>;

    public function new(?values: StringMap<TemplateValue>) {
        this.values = values != null ? values : new StringMap();
    }

    public static inline function empty(): TemplateContext {
        return new TemplateContext();
    }

    public inline function set(key: String, value: TemplateValue): Void {
        values.set(key, value);
    }

    public inline function get(key: String): Null<TemplateValue> {
        return values.get(key);
    }

    public inline function exists(key: String): Bool {
        return values.exists(key);
    }

    public inline function keys(): Iterator<String> {
        return values.keys();
    }

    public function copy(): TemplateContext {
        var next = new StringMap<TemplateValue>();
        for (k in values.keys()) {
            next.set(k, values.get(k));
        }
        return new TemplateContext(next);
    }

    public function mergeFrom(other: TemplateContext): Void {
        for (k in other.keys()) {
            set(k, other.get(k));
        }
    }
}

enum TemplateValue {
    VNull;
    VString(value: String);
    VBool(value: Bool);
    VInt(value: Int);
    VFloat(value: Float);
    VArray(items: Array<TemplateValue>);
    VObject(fields: TemplateContext);
}

class TemplateValueTools {
    public static function truthy(value: Null<TemplateValue>): Bool {
        if (value == null) return false;
        return switch (value) {
            case VNull: false;
            case VBool(b): b;
            case VString(s): s != "";
            case VInt(i): i != 0;
            case VFloat(f): f != 0.0;
            case VArray(items): items != null && items.length > 0;
            case VObject(_): true;
        }
    }

    public static function toString(value: Null<TemplateValue>): String {
        if (value == null) return "";
        return switch (value) {
            case VNull: "";
            case VBool(b): b ? "true" : "false";
            case VString(s): s;
            case VInt(i): Std.string(i);
            case VFloat(f): Std.string(f);
            case VArray(_): "";
            case VObject(_): "";
        }
    }

    public static function equals(a: Null<TemplateValue>, b: Null<TemplateValue>): Bool {
        if (a == null || b == null) return a == null && b == null;
        return switch [a, b] {
            case [VNull, VNull]: true;
            case [VBool(x), VBool(y)]: x == y;
            case [VString(x), VString(y)]: x == y;
            case [VInt(x), VInt(y)]: x == y;
            case [VFloat(x), VFloat(y)]: x == y;
            case [VInt(x), VFloat(y)]: x == y;
            case [VFloat(x), VInt(y)]: x == y;
            default: false;
        }
    }
}
