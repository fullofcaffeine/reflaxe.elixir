package reflaxe.elixir.ast.naming;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.NameUtils;

/**
 * ElixirNaming: Centralized Elixir-specific naming conventions for variables
 *
 * WHY: Eliminate code duplication by centralizing all Elixir variable naming rules
 * in one place. Previously had 3 different snake_case implementations violating DRY.
 * This module provides a single source of truth for variable naming conventions.
 *
 * WHAT: Handles all Elixir-specific variable naming requirements including:
 * - Snake_case conversion via delegation to NameUtils
 * - Special macro preservation (__MODULE__, __ENV__, etc.)
 * - Compiler temp variable handling (_g, _g1, etc.)
 * - Underscore prefix semantics for unused variables
 * - Reserved keyword escaping
 * - Numeric prefix handling
 *
 * HOW: Acts as an adapter layer over the pure NameUtils.toSnakeCase function,
 * applying Elixir-specific rules before and after the core conversion.
 *
 * ARCHITECTURE BENEFITS:
 * - DRY: Single source of truth for snake_case conversion
 * - Separation of Concerns: Pure conversion (NameUtils) vs language rules (this)
 * - Testability: Can unit test Elixir rules independently
 * - Maintainability: All naming rules in one place
 *
 * @see reflaxe.elixir.ast.NameUtils for core snake_case conversion
 * @see reflaxe.elixir.ast.naming.ElixirAtom for atom naming
 */
class ElixirNaming {

    /**
     * Convert a Haxe identifier to a valid Elixir variable name
     *
     * WHY: Elixir has specific rules for variable names that differ from Haxe
     * WHAT: Applies all Elixir-specific transformations while preserving semantics
     * HOW: Special case handling → snake_case conversion → keyword escaping
     *
     * Examples:
     * - "_" → "_" (preserve wildcard semantics)
     * - "_g" → "_g" (compiler temp preserved)
     * - "__MODULE__" → "__MODULE__" (special macro)
     * - "_FooBar" → "_foo_bar" (unused variable)
     * - "HTTPServer" → "http_server" (acronym handling)
     * - "when" → "when_" (keyword escaping)
     * - "tempResult" → "temp_result" (camelCase to snake_case)
     */
    public static function toVarName(ident: String): String {
        // Handle null/empty
        if (ident == null || ident.length == 0) return "item";

        // 1. Special macros - preserve exactly
        if (isSpecialMacro(ident)) return ident;

        // 2. Single underscore - preserve wildcard semantics
        if (ident == "_") return "_";

        // 3. Compiler temps - preserve exactly (_g, _g1, etc.)
        // Haxe intentionally prefixes many temps with `_` to avoid Elixir's unused-variable warnings.
        // Keep the name as-is; later hygiene passes can still underscore/rename when appropriate.
        if (isCompilerTemp(ident)) return ident;

        // 4. Capture leading underscores (indicates unused in Elixir)
        var underscorePrefix = "";
        var coreIdent = ident;
        while (coreIdent.length > 0 && coreIdent.charAt(0) == "_") {
            underscorePrefix += "_";
            coreIdent = coreIdent.substr(1);
        }

        // 5. Convert core identifier to snake_case using NameUtils
        var snakeCased = NameUtils.toSnakeCase(coreIdent);

        // 6. Reattach underscore prefix for unused variable semantics
        var result = underscorePrefix + snakeCased;

        // 7. Handle numeric prefix (invalid in Elixir)
        if (result.length > 0 && isNumericStart(result)) {
            result = "_" + result;
        }

        // 8. Escape reserved keywords
        result = escapeIfReserved(result);

        // 9. Final fallback for empty results
        if (result.length == 0) result = "item";

        return result;
    }

    /**
     * Check if a string is an Elixir special macro that should be preserved
     */
    static function isSpecialMacro(s: String): Bool {
        return switch(s) {
            case "__MODULE__" | "__FILE__" | "__ENV__" | "__DIR__" | "__CALLER__" | "__STACKTRACE__": true;
            default: false;
        }
    }

    /**
     * Check if a string is a compiler-generated temporary variable
     * Pattern: _g, _g1, _g2, etc.
     */
    static function isCompilerTemp(s: String): Bool {
        if (s.length < 2 || s.charAt(0) != "_" || s.charAt(1) != "g") return false;
        if (s.length == 2) return true; // Just "_g"

        // Check if everything after _g is a number
        for (i in 2...s.length) {
            var c = s.charAt(i);
            if (c < "0" || c > "9") return false;
        }
        return true;
    }

    // NOTE: We intentionally do not strip leading underscores for compiler temps.

    /**
     * Check if a string starts with a numeric character
     */
    static function isNumericStart(s: String): Bool {
        if (s.length == 0) return false;
        var c = s.charAt(0);
        return c >= "0" && c <= "9";
    }

    /**
     * Complete list of Elixir reserved keywords
     */
    static var RESERVED_KEYWORDS = [
        // Core keywords
        "after", "and", "catch", "cond", "do", "else", "end", "false", "fn",
        "in", "nil", "not", "or", "rescue", "true", "when", "with", "try",

        // Common special forms and macros
        "alias", "case", "def", "defp", "defmodule", "defmacro", "defmacrop",
        "defstruct", "defdelegate", "defprotocol", "defimpl", "for", "if",
        "import", "quote", "receive", "require", "super", "unless",
        "unquote", "use"
    ];

    /**
     * Check if a name is an Elixir reserved keyword
     */
    public static function isReserved(name: String): Bool {
        return RESERVED_KEYWORDS.indexOf(name) != -1;
    }

    /**
     * Escape a reserved keyword by appending underscore
     * Convention: Suffix with single underscore (e.g., "when_", "do_")
     */
    static function escapeIfReserved(name: String): String {
        if (isReserved(name)) {
            return name + "_";
        }
        return name;
    }
}

#end
