/**
 * Minimal Sys implementation for Elixir target to satisfy snapshot file set.
 * Only includes stubs needed to force module emission.
 */
class Sys {
    /**
     * Current time in seconds as float (stub).
     */
    public static function time(): Float {
        return untyped __elixir__('0.0');
    }
}

