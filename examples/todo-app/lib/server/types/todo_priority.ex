defmodule TodoPriority do
  @moduledoc """
  TodoPriority enum generated from Haxe
  
  
 * Todo priority levels
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :low |
    :medium |
    :high

  @doc "Creates low enum value"
  @spec low() :: :low
  def low(), do: :low

  @doc "Creates medium enum value"
  @spec medium() :: :medium
  def medium(), do: :medium

  @doc "Creates high enum value"
  @spec high() :: :high
  def high(), do: :high

  # Predicate functions for pattern matching
  @doc "Returns true if value is low variant"
  @spec is_low(t()) :: boolean()
  def is_low(:low), do: true
  def is_low(_), do: false

  @doc "Returns true if value is medium variant"
  @spec is_medium(t()) :: boolean()
  def is_medium(:medium), do: true
  def is_medium(_), do: false

  @doc "Returns true if value is high variant"
  @spec is_high(t()) :: boolean()
  def is_high(:high), do: true
  def is_high(_), do: false

end
