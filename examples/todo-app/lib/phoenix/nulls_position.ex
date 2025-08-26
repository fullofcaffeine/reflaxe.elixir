defmodule NullsPosition do
  @moduledoc """
  NullsPosition enum generated from Haxe
  
  
   * Nulls position in ordering
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :first |
    :last |
    :default

  @doc "Creates first enum value"
  @spec first() :: :first
  def first(), do: :first

  @doc "Creates last enum value"
  @spec last() :: :last
  def last(), do: :last

  @doc "Creates default enum value"
  @spec default() :: :default
  def default(), do: :default

  # Predicate functions for pattern matching
  @doc "Returns true if value is first variant"
  @spec is_first(t()) :: boolean()
  def is_first(:first), do: true
  def is_first(_), do: false

  @doc "Returns true if value is last variant"
  @spec is_last(t()) :: boolean()
  def is_last(:last), do: true
  def is_last(_), do: false

  @doc "Returns true if value is default variant"
  @spec is_default(t()) :: boolean()
  def is_default(:default), do: true
  def is_default(_), do: false

end
