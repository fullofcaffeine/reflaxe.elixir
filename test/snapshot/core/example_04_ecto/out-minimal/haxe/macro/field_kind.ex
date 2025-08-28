defmodule FieldKind do
  @moduledoc """
  FieldKind enum generated from Haxe
  
  
  	Represents a field kind.
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:f_var, term(), term()} |
    {:f_method, term()}

  @doc """
  Creates f_var enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec f_var(term(), term()) :: {:f_var, term(), term()}
  def f_var(arg0, arg1) do
    {:f_var, arg0, arg1}
  end

  @doc """
  Creates f_method enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec f_method(term()) :: {:f_method, term()}
  def f_method(arg0) do
    {:f_method, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is f_var variant"
  @spec is_f_var(t()) :: boolean()
  def is_f_var({:f_var, _}), do: true
  def is_f_var(_), do: false

  @doc "Returns true if value is f_method variant"
  @spec is_f_method(t()) :: boolean()
  def is_f_method({:f_method, _}), do: true
  def is_f_method(_), do: false

  @doc "Extracts value from f_var variant, returns {:ok, value} or :error"
  @spec get_f_var_value(t()) :: {:ok, {term(), term()}} | :error
  def get_f_var_value({:f_var, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_f_var_value(_), do: :error

  @doc "Extracts value from f_method variant, returns {:ok, value} or :error"
  @spec get_f_method_value(t()) :: {:ok, term()} | :error
  def get_f_method_value({:f_method, value}), do: {:ok, value}
  def get_f_method_value(_), do: :error

end
