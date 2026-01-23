package haxe;

import haxe.format.JsonParser;

#if (!macro && elixir_output)
import elixir.Jason;
#end

/**
 * Json
 *
 * WHAT
 * - Cross-platform JSON API (`haxe.Json`) for the Elixir target.
 *
 * WHY
 * - Haxe libraries commonly depend on `haxe.Json.parse/stringify`.
 * - On BEAM we can decode JSON efficiently via `Jason`, while keeping encoding behavior
 *   aligned with Haxe’s `haxe.format.JsonPrinter` (supports `replacer` + `space`).
 *
 * HOW
 * - `parse/1` delegates to `Jason.decode!/1` (raises on invalid JSON, matching Haxe semantics).
 * - `stringify/3` delegates to `haxe.format.JsonPrinter.print/3`.
 */
@:coreApi
class Json {
    /**
     * Parses given JSON-encoded `text` and returns the resulting value.
     *
     * NOTE
     * - We decode to Elixir terms (maps/lists) with **string keys** (Jason default).
     * - Accessing decoded maps by field requires dynamic map lookup to support string keys.
     */
    public static inline function parse(text: String): Dynamic {
        #if (!macro && elixir_output)
        return cast Jason.decodeStrict(text);
        #else
        return JsonParser.parse(text);
        #end
    }

    /**
     * Encodes the given `value` and returns the resulting JSON string.
     *
     * Supports `replacer` and `space` via `haxe.format.JsonPrinter`.
     */
    public static inline function stringify(value: Dynamic, ?replacer: (key: Dynamic, value: Dynamic) -> Dynamic, ?space: String): String {
        return haxe.format.JsonPrinter.print(value, replacer, space);
    }
}
