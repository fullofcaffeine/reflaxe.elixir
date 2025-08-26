defmodule OrderDirection do
  @moduledoc """
  OrderDirection enum generated from Haxe
  
  
   * Order by directions
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :a_s_c |
    :d_e_s_c

  @doc "Creates a_s_c enum value"
  @spec a_s_c() :: :a_s_c
  def a_s_c(), do: :a_s_c

  @doc "Creates d_e_s_c enum value"
  @spec d_e_s_c() :: :d_e_s_c
  def d_e_s_c(), do: :d_e_s_c

  # Predicate functions for pattern matching
  @doc "Returns true if value is a_s_c variant"
  @spec is_a_s_c(t()) :: boolean()
  def is_a_s_c(:a_s_c), do: true
  def is_a_s_c(_), do: false

  @doc "Returns true if value is d_e_s_c variant"
  @spec is_d_e_s_c(t()) :: boolean()
  def is_d_e_s_c(:d_e_s_c), do: true
  def is_d_e_s_c(_), do: false

end
