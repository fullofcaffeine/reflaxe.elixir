package shared;

import StringTools;
import haxe.crypto.Md5;
#if (elixir || reflaxe_runtime)
import elixir.Enum;
#end

/**
 * AvatarTools
 *
 * WHAT
 * - Tiny helper for deriving user avatars (initials + deterministic color), with an optional
 *   Gravatar URL when an email is present.
 *
 * WHY
 * - The todo-app showcase benefits from richer UI without introducing new DB schema fields.
 * - Avatars are deterministic and derived from existing identity fields (name/email).
 *
 * HOW
 * - Initials: derived from name (preferred) or email local-part fallback.
 * - Color: stable palette index derived from a simple string hash.
 * - Gravatar URL: computed from a lowercase-trimmed email and MD5:
 *   - All targets: `haxe.crypto.Md5.encode/1`
 *
 * Notes
 * - `haxe.crypto.Md5` is a stdlib surface. In Elixir builds, Reflaxe.Elixir provides an override
 *   so this stays efficient and idiomatic on BEAM while keeping the same API for JS (genes).
 */
class AvatarTools {
    static inline var DEFAULT_SIZE = 64;

    static final palette: Array<String> = [
        "bg-blue-600",
        "bg-indigo-600",
        "bg-violet-600",
        "bg-purple-600",
        "bg-pink-600",
        "bg-rose-600",
        "bg-emerald-600",
        "bg-teal-600",
        "bg-cyan-600",
        "bg-amber-600"
    ];

    public static function normalizeEmail(email: String): String {
        return StringTools.trim(email).toLowerCase();
    }

    /**
     * Safe array access that works across targets.
     *
     * Elixir: arrays are represented as lists, so we use `Enum.at/2`.
     * JS: arrays are native and can be indexed directly.
     */
    static inline function safeArrayAt<T>(array: Array<T>, index: Int): Null<T> {
        #if (elixir || reflaxe_runtime)
        return Enum.at(array, index);
        #else
        if (index < 0 || index >= array.length) return null;
        return array[index];
        #end
    }

    public static function initials(name: String, email: String): String {
        var trimmedName = StringTools.trim(name);
        if (trimmedName != "") return initialsFromName(trimmedName);

        var normalizedEmail = normalizeEmail(email);
        if (normalizedEmail != "") return initialsFromEmail(normalizedEmail);

        return "??";
    }

    /**
     * Returns a stable Tailwind background class for the user’s avatar.
     *
     * The returned value is deterministic for a given (email/name) so the UI stays consistent
     * without storing extra fields in the DB.
     */
    public static function avatarBgClass(name: String, email: String): String {
        var seed = normalizeEmail(email);
        if (seed == "") seed = StringTools.trim(name).toLowerCase();
        if (seed == "") seed = "unknown";
        var idx = hashToIndex(seed, palette.length);

        var chosen = safeArrayAt(palette, idx);
        return chosen != null ? chosen : "bg-gray-600";
    }

    /**
     * Inline CSS style for a Gravatar background image.
     *
     * Server-only usage today (LiveView templates). Safe to call from the client too, but keep in
     * mind this produces a `background-image: url(...)` string, which you should not build from
     * untrusted user input.
     */
    public static function avatarStyle(name: String, email: String, ?size: Int): String {
        var chosenSize = size != null ? size : DEFAULT_SIZE;
        var url = gravatarUrl(email, chosenSize);
        return url != null
            ? 'background-image: url(\'${url}\'); background-size: cover; background-position: center;'
            : "";
    }

    /**
     * Returns a Gravatar URL for the given email, or `null` if the email is empty.
     *
     * Cross-target behavior:
     * - All targets call `haxe.crypto.Md5.encode/1`.
     * - In Elixir builds, Reflaxe.Elixir overrides `haxe.crypto.Md5` to delegate to BEAM-native
     *   `:crypto` so call sites stay portable while output stays idiomatic/fast.
     */
    public static function gravatarUrl(email: String, ?size: Int): Null<String> {
        var normalizedEmail = normalizeEmail(email);
        if (normalizedEmail == "") return null;

        var chosenSize = size != null ? size : DEFAULT_SIZE;
        var hash = Md5.encode(normalizedEmail).toLowerCase();

        return 'https://www.gravatar.com/avatar/${hash}?d=identicon&s=${chosenSize}';
    }

    static function initialsFromName(trimmedName: String): String {
        var parts = trimmedName.split(" ").filter(p -> StringTools.trim(p) != "");

        if (parts.length >= 2) {
            var first = safeArrayAt(parts, 0);
            var second = safeArrayAt(parts, 1);

            var a = (first != null && first != "") ? first.charAt(0) : "";
            var b = (second != null && second != "") ? second.charAt(0) : "";

            return (a + b).toUpperCase();
        }

        var only = parts.length == 1 ? safeArrayAt(parts, 0) : trimmedName;
        if (only == null || only == "") return "??";
        if (only.length >= 2) return (only.charAt(0) + only.charAt(1)).toUpperCase();
        return only.charAt(0).toUpperCase();
    }

    static function initialsFromEmail(normalizedEmail: String): String {
        var parts = normalizedEmail.split("@");
        var local = safeArrayAt(parts, 0);
        if (local == null) local = normalizedEmail;

        if (local.length >= 2) return (local.charAt(0) + local.charAt(1)).toUpperCase();
        if (local.length == 1) return local.charAt(0).toUpperCase();
        return "??";
    }

    static function hashToIndex(input: String, modulo: Int): Int {
        var hash = 0;
        for (i in 0...input.length) {
            hash = (hash * 31 + input.charCodeAt(i)) & 0x7fffffff;
        }
        return modulo == 0 ? 0 : (hash % modulo);
    }
}
