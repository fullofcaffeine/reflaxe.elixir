package elixir.types;

/**
 * Type-safe Atom abstract for Elixir atoms
 * 
 * WHY: Elixir atoms are fundamental constants used extensively throughout 
 * the language. This abstract provides type-safe atom creation and usage,
 * preventing accidental string/atom confusion and enabling explicit intent.
 * 
 * WHAT: A zero-cost abstraction over String that compiles to Elixir atoms.
 * When you use Atom in your Haxe code, it generates proper atoms in Elixir.
 * 
 * HOW: The abstract wraps a String internally but tells the compiler to
 * generate atoms in the output. The compiler recognizes Atom types and
 * generates EAtom AST nodes instead of EString.
 * 
 * USAGE:
 * ```haxe
 * // Create atoms explicitly
 * var myAtom: Atom = "millisecond";
 * var status: Atom = "ok";
 * 
 * // Use in enum abstracts
 * enum abstract TimeUnit(Atom) to Atom {
 *     var Second = "second";
 *     var Millisecond = "millisecond";
 *     var Microsecond = "microsecond";
 * }
 * 
 * // Pass to Elixir functions expecting atoms
 * DateTime.from_unix(timestamp, TimeUnit.Millisecond);
 * ```
 * 
 * BENEFITS:
 * - Type safety: Can't accidentally pass strings where atoms are expected
 * - Explicit intent: Clear when you want an atom vs a string
 * - Zero runtime cost: Abstracts compile away completely
 * - IDE support: IntelliSense knows the type is an atom
 * 
 * COMPILER INTEGRATION:
 * The Reflaxe.Elixir compiler detects when an expression has type Atom
 * and generates EAtom AST nodes instead of EString. This happens in
 * ElixirASTBuilder when checking expr.t (the expression's type).
 * 
 * @see docs/04-api-reference/ATOM_TYPE.md - Complete atom type documentation
 * @since 1.0.0
 */
abstract Atom(String) from String to String {
    
    /**
     * Create an Atom from a string literal
     * 
     * @param s The string to convert to an atom
     */
    public inline function new(s: String) {
        this = s;
    }
    
    /**
     * Convert atom to string representation
     * Useful for debugging or string operations
     * 
     * @return The string value of the atom
     */
    public inline function toString(): String {
        return this;
    }
    
    /**
     * Check equality with another atom
     * 
     * @param other The atom to compare with
     * @return True if atoms are equal
     */
    @:op(A == B)
    public inline function equals(other: Atom): Bool {
        return this == cast other;
    }
    
    /**
     * Check inequality with another atom
     * 
     * @param other The atom to compare with
     * @return True if atoms are not equal
     */
    @:op(A != B)
    public inline function notEquals(other: Atom): Bool {
        return this != cast other;
    }
    
    /**
     * Static helper to create an atom
     * Alternative to implicit conversion
     * 
     * @param s The string to convert
     * @return An Atom
     */
    public static inline function fromString(s: String): Atom {
        return new Atom(s);
    }
    
    // Common Elixir atoms as static constants
    public static inline var OK: Atom = "ok";
    public static inline var ERROR: Atom = "error";
    public static inline var TRUE: Atom = "true";
    public static inline var FALSE: Atom = "false";
    public static inline var NIL: Atom = "nil";
    public static inline var UNDEFINED: Atom = "undefined";
    public static inline var INFINITY: Atom = "infinity";
    public static inline var TIMEOUT: Atom = "timeout";
    public static inline var NORMAL: Atom = "normal";
    public static inline var SHUTDOWN: Atom = "shutdown";
    
    // Comparison result atoms
    public static inline var LT: Atom = "lt";
    public static inline var EQ: Atom = "eq";
    public static inline var GT: Atom = "gt";
    
    // Time unit atoms (for DateTime operations)
    public static inline var SECOND: Atom = "second";
    public static inline var MILLISECOND: Atom = "millisecond";
    public static inline var MICROSECOND: Atom = "microsecond";
    public static inline var NANOSECOND: Atom = "nanosecond";
}