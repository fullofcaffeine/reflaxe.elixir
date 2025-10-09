package haxe.ds;

/**
 * Universal Option<T> type for type-safe null handling across all Haxe targets.
 * 
 * Inspired by Gleam's approach to type-safe BEAM development: explicit over implicit,
 * compile-time safety over runtime convenience.
 * 
 * ## Cross-Platform Compilation
 * 
 * Option values compile to idiomatic constructs per target:
 * - **Elixir**: `{:ok, value}` / `:error` atoms for clear pattern matching
 * - **JavaScript**: discriminated unions with tagged types
 * - **Python**: dataclasses with proper type hints
 * - **Other targets**: standard enum with type safety
 * 
 * ## Design Philosophy
 * 
 * Following Gleam's BEAM abstraction principles:
 * 1. **Type safety first** - No null pointer exceptions, exhaustive pattern matching
 * 2. **Explicit over implicit** - Tagged tuples, not nil, for clarity
 * 3. **BEAM idioms** - Compiles to patterns BEAM developers expect
 * 4. **Fault tolerance** - Use Option for expected absence, crashes for bugs
 * 5. **Functional composition** - Full monadic operations for chaining
 * 
 * ## Usage Patterns
 * 
 * ```haxe
 * // Construction
 * var user: Option<User> = findUser(id);  // Some(user) or None
 * 
 * // Pattern matching (recommended)
 * switch (user) {
 *     case Some(u): processUser(u);
 *     case None: handleMissingUser();
 * }
 * 
 * // Functional composition
 * var email = user
 *     .map(u -> u.email)
 *     .filter(e -> e.length > 0)
 *     .unwrap("no-email@example.com");
 * 
 * // OTP integration
 * var result = user.toResult("User not found");
 * ```
 * 
 * @see OptionTools for functional operations and BEAM integration
 */
// TODO: Future improvement - add AST transformer to properly map Some→ok and None→error
// Currently @:elixirIdiomatic will just lowercase to {:some/:none} which isn't ideal.
// A proper transformer would detect Option<T> specifically and map to {:ok/:error} for
// true Elixir idiomatic patterns. For now, developers should prefer Result<T,E> for 
// Elixir applications to get proper {:ok/:error} patterns.
enum Option<T> {
    /**
     * Represents a value that is present.
     * 
     * Compiles to:
     * - Elixir: `{:some, value}` (will be `{:ok, value}` when AST transformer is improved)
     * - JavaScript: `{tag: "some", value: value}`
     * - Other targets: enum variant with data
     * 
     * @param v The contained value
     */
    Some(v: T);
    
    /**
     * Represents the absence of a value.
     * 
     * Compiles to:
     * - Elixir: `:none` (will be `:error` when AST transformer is improved)
     * - JavaScript: `{tag: "none"}`
     * - Other targets: enum variant without data
     */
    None;
}
