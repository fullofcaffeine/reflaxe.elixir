defmodule FunctionKind do
  @moduledoc """
  FunctionKind enum generated from Haxe
  
  
  	Represents function kind in the AST
  
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :f_anonymous |
    {:f_named, term(), term()} |
    :f_arrow

  @doc "Creates f_anonymous enum value"
  @spec f_anonymous() :: :f_anonymous
  def f_anonymous(), do: :f_anonymous

  @doc """
  Creates f_named enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec f_named(term(), term()) :: {:f_named, term(), term()}
  def f_named(arg0, arg1) do
    {:f_named, arg0, arg1}
  end

  @doc "Creates f_arrow enum value"
  @spec f_arrow() :: :f_arrow
  def f_arrow(), do: :f_arrow

  # Predicate functions for pattern matching
  @doc "Returns true if value is f_anonymous variant"
  @spec is_f_anonymous(t()) :: boolean()
  def is_f_anonymous(:f_anonymous), do: true
  def is_f_anonymous(_), do: false

  @doc "Returns true if value is f_named variant"
  @spec is_f_named(t()) :: boolean()
  def is_f_named({:f_named, _}), do: true
  def is_f_named(_), do: false

  @doc "Returns true if value is f_arrow variant"
  @spec is_f_arrow(t()) :: boolean()
  def is_f_arrow(:f_arrow), do: true
  def is_f_arrow(_), do: false

  @doc "Extracts value from f_named variant, returns {:ok, value} or :error"
  @spec get_f_named_value(t()) :: {:ok, {term(), term()}} | :error
  def get_f_named_value({:f_named, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_f_named_value(_), do: :error

end
