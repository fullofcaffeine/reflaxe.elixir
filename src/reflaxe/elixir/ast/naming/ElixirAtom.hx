package reflaxe.elixir.ast.naming;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.elixir.ast.NameUtils;

/**
 * ElixirAtom: Type-safe automatic snake_case conversion for Elixir atoms
 * 
 * WHY: Eliminate 71+ manual toSnakeCase() calls scattered throughout the compiler
 * by centralizing naming conventions at the type level. This ensures consistency
 * and prevents forgetting conversions that lead to pattern matching failures.
 * 
 * WHAT: An abstract type that automatically converts any input string to snake_case
 * for Elixir atoms. Used for enum constructors, map keys, options, and atom literals.
 * Provides implicit conversions via @:from and an escape hatch via raw().
 * 
 * HOW: 
 * - Implicit conversion from String via @:from
 * - Automatic toSnakeCase() application in constructor
 * - raw() method for special cases that need exact strings
 * - Common atom constants for frequently used values
 * - Zero runtime cost through inline functions
 * 
 * WHY ABSTRACT TYPE INSTEAD OF ENUM ABSTRACT:
 * - Enum abstracts are for finite, known sets of values (like Phoenix actions)
 * - We need to handle ANY arbitrary string and transform it to snake_case
 * - Must support @:from for implicit conversions (enum abstracts don't)
 * - Primary purpose is transformation, not enumeration of constants
 * - Example: Converting any EnumField.name or dynamic string to snake_case atom
 * 
 * COMPILATION CONTEXT:
 * - This entire type only exists during compilation (macro || reflaxe_runtime)
 * - Not available at runtime - the generated Elixir code has plain strings
 * - All methods are inline, so they're expanded at call sites during compilation
 * - EnumField conversion works because it's also a compile-time type
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles atom naming conventions
 * - DRY Principle: Conversion logic in one place
 * - Type Safety: Can't accidentally pass unconverted strings
 * - Zero Cost: All inline functions, no runtime overhead
 * 
 * EDGE CASES:
 * - Already snake_case strings remain unchanged (idempotent)
 * - Special forms like __MODULE__ use raw() to bypass conversion
 * - Empty strings and null handled by NameUtils
 * 
 * @see reflaxe.elixir.ast.NameUtils for the underlying conversion logic
 */
abstract ElixirAtom(String) to String {
    /**
     * Create a new ElixirAtom with automatic snake_case conversion
     * 
     * Examples:
     * - new ElixirAtom("TodoUpdates") → "todo_updates"
     * - new ElixirAtom("HTTPServer") → "http_server"
     * - new ElixirAtom("already_snake") → "already_snake" (idempotent)
     */
    inline public function new(s: String) {
        this = NameUtils.toSnakeCase(s);
    }
    
    /**
     * Implicit conversion from String to ElixirAtom
     * Enables automatic conversion at call sites
     */
    @:from
    static inline public function fromString(s: String): ElixirAtom {
        return new ElixirAtom(s);
    }
    
    /**
     * Implicit conversion from EnumField to ElixirAtom
     * EnumField is a compile-time type that exists in macro/reflaxe_runtime context
     * Automatically extracts and converts the enum field name to snake_case
     * 
     * Note: No additional #if macro guard needed since the entire file
     * is already wrapped in #if (macro || reflaxe_runtime)
     */
    @:from
    static inline public function fromEnumField(ef: EnumField): ElixirAtom {
        return new ElixirAtom(ef.name);
    }
    
    /**
     * Create an ElixirAtom without any conversion (escape hatch)
     * 
     * WARNING: Use sparingly! This bypasses all naming conventions.
     * Only use for:
     * - Special Elixir forms (__MODULE__, __struct__, etc.)
     * - Already correctly formatted atoms from external sources
     * - Atoms with special characters that shouldn't be converted
     * 
     * @param s The exact string to use as the atom value
     * @return An ElixirAtom with the exact string provided
     */
    static inline public function raw(s: String): ElixirAtom {
        return cast s;
    }
    
    // ========================================================================
    // Common Elixir Atoms
    // ========================================================================
    
    /** The :ok atom used in {:ok, value} tuples */
    static inline public function ok(): ElixirAtom {
        return raw("ok");
    }
    
    /** The :error atom used in {:error, reason} tuples */
    static inline public function error(): ElixirAtom {
        return raw("error");
    }
    
    /** The :nil atom representing null/nothing */
    static inline public function nil(): ElixirAtom {
        return raw("nil");
    }
    
    /** The :true atom for boolean true */
    static inline public function true_(): ElixirAtom {
        return raw("true");
    }
    
    /** The :false atom for boolean false */
    static inline public function false_(): ElixirAtom {
        return raw("false");
    }
    
    // ========================================================================
    // Special Elixir Forms
    // ========================================================================
    
    /** The __MODULE__ special form */
    static inline public function module_(): ElixirAtom {
        return raw("__MODULE__");
    }
    
    /** The __struct__ key in Elixir structs */
    static inline public function struct_(): ElixirAtom {
        return raw("__struct__");
    }
    
    /** The __aliases__ special form */
    static inline public function aliases_(): ElixirAtom {
        return raw("__aliases__");
    }
    
    /** The __ENV__ special form */
    static inline public function env_(): ElixirAtom {
        return raw("__ENV__");
    }
    
    /** The __CALLER__ special form */
    static inline public function caller_(): ElixirAtom {
        return raw("__CALLER__");
    }
    
    // ========================================================================
    // Common Phoenix Atoms
    // ========================================================================
    
    /** The :info flash type */
    static inline public function info(): ElixirAtom {
        return raw("info");
    }
    
    /** The :warning flash type */
    static inline public function warning(): ElixirAtom {
        return raw("warning");
    }
    
    /** The :danger flash type */
    static inline public function danger(): ElixirAtom {
        return raw("danger");
    }
    
    /** The :success flash type */
    static inline public function success(): ElixirAtom {
        return raw("success");
    }
}

#end