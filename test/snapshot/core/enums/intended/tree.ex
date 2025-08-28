defmodule Tree do
  @moduledoc """
  Tree enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:leaf, term()} |
    {:node_, term(), term()}

  @doc """
  Creates leaf enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec leaf(term()) :: {:leaf, term()}
  def leaf(arg0) do
    {:leaf, arg0}
  end

  @doc """
  Creates node_ enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec node_(term(), term()) :: {:node_, term(), term()}
  def node_(arg0, arg1) do
    {:node_, arg0, arg1}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is leaf variant"
  @spec is_leaf(t()) :: boolean()
  def is_leaf({:leaf, _}), do: true
  def is_leaf(_), do: false

  @doc "Returns true if value is node_ variant"
  @spec is_node_(t()) :: boolean()
  def is_node_({:node_, _}), do: true
  def is_node_(_), do: false

  @doc "Extracts value from leaf variant, returns {:ok, value} or :error"
  @spec get_leaf_value(t()) :: {:ok, term()} | :error
  def get_leaf_value({:leaf, value}), do: {:ok, value}
  def get_leaf_value(_), do: :error

  @doc "Extracts value from node_ variant, returns {:ok, value} or :error"
  @spec get_node__value(t()) :: {:ok, {term(), term()}} | :error
  def get_node__value({:node_, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_node__value(_), do: :error

end
