package reflaxe.js;

/**
 * Unknown
 *
 * WHAT
 * - Opaque type representing an unknown JavaScript value at interop boundaries
 *   (Promise rejections, thrown values, external callbacks).
 *
 * WHY
 * - JavaScript allows rejecting/throwing any value (Error, string, object, etc.).
 * - We avoid exposing `Dynamic` in public APIs while still modeling the reality of JS.
 *
 * HOW
 * - Implemented as an abstract over `Dynamic` but named and documented as an explicit boundary type.
 * - Safe helpers allow narrowing when appropriate.
 */
abstract Unknown(Dynamic) from Dynamic to Dynamic {
    /**
     * Best-effort conversion for debugging/logging.
     */
    public inline function toDebugString(): String {
        return Std.string(this);
    }

    /**
     * Narrow to `js.lib.Error` when the value is an Error; otherwise `null`.
     */
    public inline function asError(): Null<js.lib.Error> {
        return Std.isOfType(this, js.lib.Error) ? cast this : null;
    }
}

