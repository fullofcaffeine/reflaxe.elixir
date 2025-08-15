defmodule Option do
  @moduledoc """
  Option enum generated from Haxe
  
  
 * Universal Option<T> type for type-safe null handling across all Haxe targets.
 * 
 * Inspired by Gleam's approach to type-safe BEAM development: explicit over implicit,
 * compile-time safety over runtime convenience.
 * 
 * ## Cross-Platform Compilation
 * 
 * Option values compile to idiomatic constructs per target:
 * - **Elixir**: `{:some, value}` / `:none` atoms for clear pattern matching
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
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:some, term()} |
    :none

  @doc """
  Creates some enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec some(term()) :: {:some, term()}
  def some(arg0) do
    {:some, arg0}
  end

  @doc "Creates none enum value"
  @spec none() :: :none
  def none(), do: :none

  # Predicate functions for pattern matching
  @doc "Returns true if value is some variant"
  @spec is_some(t()) :: boolean()
  def is_some({:some, _}), do: true
  def is_some(_), do: false

  @doc "Returns true if value is none variant"
  @spec is_none(t()) :: boolean()
  def is_none(:none), do: true
  def is_none(_), do: false

  @doc "Extracts value from some variant, returns {:ok, value} or :error"
  @spec get_some_value(t()) :: {:ok, term()} | :error
  def get_some_value({:some, value}), do: {:ok, value}
  def get_some_value(_), do: :error

end
