package;

import phoenix.Presence;

/**
 * Presence metadata nil-guard coalesce tests
 *
 * Verifies that after an `if (meta == null)` guard, subsequent field access
 * on `meta` is safe by coalescing to an empty map `%{}` when needed.
 * Covers both one-liner and do/end styles, plus negative cases to prevent
 * over-coalescing.
 */
typedef Meta = {
    var onlineAt: Float;
    var userName: String;
}

class Main {
    static function main() {}

    // One-liner `if` style: should insert `currentMeta = %{}` before field access
    public static function needsCoalesceOneLiner(socket: Dynamic, key: String): String {
        var currentMeta: Null<Meta> = maybeGetMeta();
        if (currentMeta == null) Presence.track(socket, key, cast {});
        var name = currentMeta.userName;
        return name;
    }

    // do/end block style: should insert `currentMeta = %{}` before field access
    public static function needsCoalesceDoEnd(socket: Dynamic, key: String): Float {
        var currentMeta: Null<Meta> = maybeGetMeta();
        if (currentMeta == null) {
            Presence.track(socket, key, cast {});
        }
        var ts = currentMeta.onlineAt;
        return ts;
    }

    // Negative: reassignment before field access prevents coalescing injection
    public static function negativeReassignPreventsInjection(socket: Dynamic, key: String): Float {
        var currentMeta: Null<Meta> = maybeGetMeta();
        if (currentMeta == null) Presence.track(socket, key, cast {});
        currentMeta = { onlineAt: 0.0, userName: "x" };
        var ts = currentMeta.onlineAt;
        return ts;
    }

    // Negative: no field access after guard, so no injection
    public static function negativeNoFieldAccess(socket: Dynamic, key: String): Int {
        var currentMeta: Null<Meta> = maybeGetMeta();
        if (currentMeta == null) Presence.track(socket, key, cast {});
        return 0;
    }

    static function maybeGetMeta(): Null<Meta> {
        return null; // simulate absence
    }
}

