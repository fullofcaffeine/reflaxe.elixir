defmodule Error do
  @moduledoc """
  Error enum generated from Haxe
  
  
	The possible IO errors that can occur

  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :blocked |
    :overflow |
    :outside_bounds |
    {:custom, term()}

  @doc "Creates blocked enum value"
  @spec blocked() :: :blocked
  def blocked(), do: :blocked

  @doc "Creates overflow enum value"
  @spec overflow() :: :overflow
  def overflow(), do: :overflow

  @doc "Creates outside_bounds enum value"
  @spec outside_bounds() :: :outside_bounds
  def outside_bounds(), do: :outside_bounds

  @doc """
  Creates custom enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec custom(term()) :: {:custom, term()}
  def custom(arg0) do
    {:custom, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is blocked variant"
  @spec is_blocked(t()) :: boolean()
  def is_blocked(:blocked), do: true
  def is_blocked(_), do: false

  @doc "Returns true if value is overflow variant"
  @spec is_overflow(t()) :: boolean()
  def is_overflow(:overflow), do: true
  def is_overflow(_), do: false

  @doc "Returns true if value is outside_bounds variant"
  @spec is_outside_bounds(t()) :: boolean()
  def is_outside_bounds(:outside_bounds), do: true
  def is_outside_bounds(_), do: false

  @doc "Returns true if value is custom variant"
  @spec is_custom(t()) :: boolean()
  def is_custom({:custom, _}), do: true
  def is_custom(_), do: false

  @doc "Extracts value from custom variant, returns {:ok, value} or :error"
  @spec get_custom_value(t()) :: {:ok, term()} | :error
  def get_custom_value({:custom, value}), do: {:ok, value}
  def get_custom_value(_), do: :error

end
