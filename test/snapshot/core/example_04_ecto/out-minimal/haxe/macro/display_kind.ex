defmodule DisplayKind do
  @moduledoc """
  DisplayKind enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :d_k_call |
    :d_k_dot |
    :d_k_structure |
    :d_k_marked |
    {:d_k_pattern, term()}

  @doc "Creates d_k_call enum value"
  @spec d_k_call() :: :d_k_call
  def d_k_call(), do: :d_k_call

  @doc "Creates d_k_dot enum value"
  @spec d_k_dot() :: :d_k_dot
  def d_k_dot(), do: :d_k_dot

  @doc "Creates d_k_structure enum value"
  @spec d_k_structure() :: :d_k_structure
  def d_k_structure(), do: :d_k_structure

  @doc "Creates d_k_marked enum value"
  @spec d_k_marked() :: :d_k_marked
  def d_k_marked(), do: :d_k_marked

  @doc """
  Creates d_k_pattern enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec d_k_pattern(term()) :: {:d_k_pattern, term()}
  def d_k_pattern(arg0) do
    {:d_k_pattern, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is d_k_call variant"
  @spec is_d_k_call(t()) :: boolean()
  def is_d_k_call(:d_k_call), do: true
  def is_d_k_call(_), do: false

  @doc "Returns true if value is d_k_dot variant"
  @spec is_d_k_dot(t()) :: boolean()
  def is_d_k_dot(:d_k_dot), do: true
  def is_d_k_dot(_), do: false

  @doc "Returns true if value is d_k_structure variant"
  @spec is_d_k_structure(t()) :: boolean()
  def is_d_k_structure(:d_k_structure), do: true
  def is_d_k_structure(_), do: false

  @doc "Returns true if value is d_k_marked variant"
  @spec is_d_k_marked(t()) :: boolean()
  def is_d_k_marked(:d_k_marked), do: true
  def is_d_k_marked(_), do: false

  @doc "Returns true if value is d_k_pattern variant"
  @spec is_d_k_pattern(t()) :: boolean()
  def is_d_k_pattern({:d_k_pattern, _}), do: true
  def is_d_k_pattern(_), do: false

  @doc "Extracts value from d_k_pattern variant, returns {:ok, value} or :error"
  @spec get_d_k_pattern_value(t()) :: {:ok, term()} | :error
  def get_d_k_pattern_value({:d_k_pattern, value}), do: {:ok, value}
  def get_d_k_pattern_value(_), do: :error

end
