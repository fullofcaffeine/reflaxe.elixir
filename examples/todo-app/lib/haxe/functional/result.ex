defmodule Result do
  @moduledoc """
  Result enum generated from Haxe
  
  
   * Universal Result<T,E> algebraic data type for safe error handling.
   * 
   * Compiles to idiomatic constructs per target:
   * - Elixir: {:ok, value} / {:error, reason} tuples
   * - JavaScript: discriminated unions with tagged types
   * - Python: dataclasses with proper type hints
   * - Other targets: standard enum with type safety
   * 
   * This implementation prioritizes:
   * - Type safety across all targets
   * - Functional composition patterns
   * - Exhaustive pattern matching support
   * - Zero-cost abstractions where possible
   * 
   * @see ResultTools for functional operations (map, flatMap, fold, etc.)
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:ok, term()} |
    {:error, term()}

  @doc """
  Creates ok enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec ok(term()) :: {:ok, term()}
  def ok(arg0) do
    {:ok, arg0}
  end

  @doc """
  Creates error enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec error(term()) :: {:error, term()}
  def error(arg0) do
    {:error, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is ok variant"
  @spec is_ok(t()) :: boolean()
  def is_ok({:ok, _}), do: true
  def is_ok(_), do: false

  @doc "Returns true if value is error variant"
  @spec is_error(t()) :: boolean()
  def is_error({:error, _}), do: true
  def is_error(_), do: false

  @doc "Extracts value from ok variant, returns {:ok, value} or :error"
  @spec get_ok_value(t()) :: {:ok, term()} | :error
  def get_ok_value({:ok, value}), do: {:ok, value}
  def get_ok_value(_), do: :error

  @doc "Extracts value from error variant, returns {:ok, value} or :error"
  @spec get_error_value(t()) :: {:ok, term()} | :error
  def get_error_value({:error, value}), do: {:ok, value}
  def get_error_value(_), do: :error

end
