package elixir;

#if (elixir || reflaxe_runtime)

/**
 * ErlangCrypto
 *
 * WHAT
 * - Small, typed wrapper around Erlang's `:crypto` module for common hashing needs.
 *
 * WHY
 * - Some integrations (e.g. Gravatar URLs) need a stable hash at runtime.
 * - We keep `untyped __elixir__()` usage inside the stdlib so application code can stay “pure Haxe”.
 *
 * HOW
 * - Calls `:crypto.hash/2` and `Base.encode16/2` directly in Elixir.
 */
class ErlangCrypto {
    /**
     * Hash a string with MD5 and return a lowercase hex digest.
     */
    extern inline public static function md5HexLower(data: String): String {
        return cast untyped __elixir__('Base.encode16(:crypto.hash(:md5, {0}), case: :lower)', data);
    }
}

#end

