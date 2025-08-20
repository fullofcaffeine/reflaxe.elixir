defmodule StringLiteralKind do
  @moduledoc """
  StringLiteralKind enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :double_quotes |
    :single_quotes

  @doc "Creates double_quotes enum value"
  @spec double_quotes() :: :double_quotes
  def double_quotes(), do: :double_quotes

  @doc "Creates single_quotes enum value"
  @spec single_quotes() :: :single_quotes
  def single_quotes(), do: :single_quotes

  # Predicate functions for pattern matching
  @doc "Returns true if value is double_quotes variant"
  @spec is_double_quotes(t()) :: boolean()
  def is_double_quotes(:double_quotes), do: true
  def is_double_quotes(_), do: false

  @doc "Returns true if value is single_quotes variant"
  @spec is_single_quotes(t()) :: boolean()
  def is_single_quotes(:single_quotes), do: true
  def is_single_quotes(_), do: false

end
