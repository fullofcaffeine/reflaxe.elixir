defmodule EmbedStrategy do
  @moduledoc """
  EmbedStrategy enum generated from Haxe
  
  
 * Embed strategies
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :replace |
    :append

  @doc "Creates replace enum value"
  @spec replace() :: :replace
  def replace(), do: :replace

  @doc "Creates append enum value"
  @spec append() :: :append
  def append(), do: :append

  # Predicate functions for pattern matching
  @doc "Returns true if value is replace variant"
  @spec is_replace(t()) :: boolean()
  def is_replace(:replace), do: true
  def is_replace(_), do: false

  @doc "Returns true if value is append variant"
  @spec is_append(t()) :: boolean()
  def is_append(:append), do: true
  def is_append(_), do: false

end
