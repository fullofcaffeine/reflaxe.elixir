defmodule QuoteStatus do
  @moduledoc """
  QuoteStatus enum generated from Haxe
  
  
  	Represents the way something is quoted.
  
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :unquoted |
    :quoted

  @doc "Creates unquoted enum value"
  @spec unquoted() :: :unquoted
  def unquoted(), do: :unquoted

  @doc "Creates quoted enum value"
  @spec quoted() :: :quoted
  def quoted(), do: :quoted

  # Predicate functions for pattern matching
  @doc "Returns true if value is unquoted variant"
  @spec is_unquoted(t()) :: boolean()
  def is_unquoted(:unquoted), do: true
  def is_unquoted(_), do: false

  @doc "Returns true if value is quoted variant"
  @spec is_quoted(t()) :: boolean()
  def is_quoted(:quoted), do: true
  def is_quoted(_), do: false

end
