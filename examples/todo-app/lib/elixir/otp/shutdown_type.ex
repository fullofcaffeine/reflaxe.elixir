defmodule ShutdownType do
  @moduledoc """
  ShutdownType enum generated from Haxe
  
  
   * Child shutdown strategy
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :brutal |
    {:timeout, term()} |
    :infinity

  @doc "Creates brutal enum value"
  @spec brutal() :: :brutal
  def brutal(), do: :brutal

  @doc """
  Creates timeout enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec timeout(term()) :: {:timeout, term()}
  def timeout(arg0) do
    {:timeout, arg0}
  end

  @doc "Creates infinity enum value"
  @spec infinity() :: :infinity
  def infinity(), do: :infinity

  # Predicate functions for pattern matching
  @doc "Returns true if value is brutal variant"
  @spec is_brutal(t()) :: boolean()
  def is_brutal(:brutal), do: true
  def is_brutal(_), do: false

  @doc "Returns true if value is timeout variant"
  @spec is_timeout(t()) :: boolean()
  def is_timeout({:timeout, _}), do: true
  def is_timeout(_), do: false

  @doc "Returns true if value is infinity variant"
  @spec is_infinity(t()) :: boolean()
  def is_infinity(:infinity), do: true
  def is_infinity(_), do: false

  @doc "Extracts value from timeout variant, returns {:ok, value} or :error"
  @spec get_timeout_value(t()) :: {:ok, term()} | :error
  def get_timeout_value({:timeout, value}), do: {:ok, value}
  def get_timeout_value(_), do: :error

end
