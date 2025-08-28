defmodule SupervisorStrategy do
  @moduledoc """
  SupervisorStrategy enum generated from Haxe
  
  
   * Supervisor restart strategy
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :one_for_one |
    :one_for_all |
    :rest_for_one |
    :simple_one_for_one

  @doc "Creates one_for_one enum value"
  @spec one_for_one() :: :one_for_one
  def one_for_one(), do: :one_for_one

  @doc "Creates one_for_all enum value"
  @spec one_for_all() :: :one_for_all
  def one_for_all(), do: :one_for_all

  @doc "Creates rest_for_one enum value"
  @spec rest_for_one() :: :rest_for_one
  def rest_for_one(), do: :rest_for_one

  @doc "Creates simple_one_for_one enum value"
  @spec simple_one_for_one() :: :simple_one_for_one
  def simple_one_for_one(), do: :simple_one_for_one

  # Predicate functions for pattern matching
  @doc "Returns true if value is one_for_one variant"
  @spec is_one_for_one(t()) :: boolean()
  def is_one_for_one(:one_for_one), do: true
  def is_one_for_one(_), do: false

  @doc "Returns true if value is one_for_all variant"
  @spec is_one_for_all(t()) :: boolean()
  def is_one_for_all(:one_for_all), do: true
  def is_one_for_all(_), do: false

  @doc "Returns true if value is rest_for_one variant"
  @spec is_rest_for_one(t()) :: boolean()
  def is_rest_for_one(:rest_for_one), do: true
  def is_rest_for_one(_), do: false

  @doc "Returns true if value is simple_one_for_one variant"
  @spec is_simple_one_for_one(t()) :: boolean()
  def is_simple_one_for_one(:simple_one_for_one), do: true
  def is_simple_one_for_one(_), do: false

end
