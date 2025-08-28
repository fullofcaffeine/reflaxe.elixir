defmodule UserOption do
  @moduledoc """
  UserOption enum generated from Haxe
  
  
   * Test for @:elixirIdiomatic annotation
   * 
   * Validates that user-defined enums with @:elixirIdiomatic annotation
   * generate idiomatic Elixir patterns ({:ok, value} / :error)
   * instead of literal patterns ({:some, value} / :none).
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:ok, term()} |
    :error

  @doc """
  Creates some enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec some(term()) :: {:ok, term()}
  def some(arg0) do
    {:ok, arg0}
  end

  @doc "Creates none enum value"
  @spec none() :: :error
  def none(), do: :error

  # Predicate functions for pattern matching
  @doc "Returns true if value is some variant"
  @spec is_some(t()) :: boolean()
  def is_some({:ok, _}), do: true
  def is_some(_), do: false

  @doc "Returns true if value is none variant"
  @spec is_none(t()) :: boolean()
  def is_none(:error), do: true
  def is_none(_), do: false

  @doc "Extracts value from some variant, returns {:ok, value} or :error"
  @spec get_some_value(t()) :: {:ok, term()} | :error
  def get_some_value({:ok, value}), do: {:ok, value}
  def get_some_value(_), do: :error

end
