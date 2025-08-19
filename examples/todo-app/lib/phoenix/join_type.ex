defmodule JoinType do
  @moduledoc """
  JoinType enum generated from Haxe
  
  
 * Join type enumeration
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :inner |
    :left |
    :right |
    :full |
    :cross

  @doc "Creates inner enum value"
  @spec inner() :: :inner
  def inner(), do: :inner

  @doc "Creates left enum value"
  @spec left() :: :left
  def left(), do: :left

  @doc "Creates right enum value"
  @spec right() :: :right
  def right(), do: :right

  @doc "Creates full enum value"
  @spec full() :: :full
  def full(), do: :full

  @doc "Creates cross enum value"
  @spec cross() :: :cross
  def cross(), do: :cross

  # Predicate functions for pattern matching
  @doc "Returns true if value is inner variant"
  @spec is_inner(t()) :: boolean()
  def is_inner(:inner), do: true
  def is_inner(_), do: false

  @doc "Returns true if value is left variant"
  @spec is_left(t()) :: boolean()
  def is_left(:left), do: true
  def is_left(_), do: false

  @doc "Returns true if value is right variant"
  @spec is_right(t()) :: boolean()
  def is_right(:right), do: true
  def is_right(_), do: false

  @doc "Returns true if value is full variant"
  @spec is_full(t()) :: boolean()
  def is_full(:full), do: true
  def is_full(_), do: false

  @doc "Returns true if value is cross variant"
  @spec is_cross(t()) :: boolean()
  def is_cross(:cross), do: true
  def is_cross(_), do: false

end
