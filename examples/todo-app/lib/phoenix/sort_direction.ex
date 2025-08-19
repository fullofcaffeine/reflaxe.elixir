defmodule SortDirection do
  @moduledoc """
  SortDirection enum generated from Haxe
  
  
 * Sort direction for queries
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :asc |
    :desc

  @doc "Creates asc enum value"
  @spec asc() :: :asc
  def asc(), do: :asc

  @doc "Creates desc enum value"
  @spec desc() :: :desc
  def desc(), do: :desc

  # Predicate functions for pattern matching
  @doc "Returns true if value is asc variant"
  @spec is_asc(t()) :: boolean()
  def is_asc(:asc), do: true
  def is_asc(_), do: false

  @doc "Returns true if value is desc variant"
  @spec is_desc(t()) :: boolean()
  def is_desc(:desc), do: true
  def is_desc(_), do: false

end
