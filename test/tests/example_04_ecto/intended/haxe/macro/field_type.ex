defmodule FieldType do
  @moduledoc """
  FieldType enum generated from Haxe
  
  
  	Represents the field type in the AST.
  
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:f_var, term(), term()} |
    {:f_fun, term()} |
    {:f_prop, term(), term(), term(), term()}

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
  Creates f_fun enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec f_fun(term()) :: {:f_fun, term()}
  def f_fun(arg0) do
    {:f_fun, arg0}
  end

  @doc """
  Creates f_prop enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
    - `arg3`: term()
  """
  @spec f_prop(term(), term(), term(), term()) :: {:f_prop, term(), term(), term(), term()}
  def f_prop(arg0, arg1, arg2, arg3) do
    {:f_prop, arg0, arg1, arg2, arg3}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is f_var variant"
  @spec is_f_var(t()) :: boolean()
  def is_f_var({:f_var, _}), do: true
  def is_f_var(_), do: false

  @doc "Returns true if value is f_fun variant"
  @spec is_f_fun(t()) :: boolean()
  def is_f_fun({:f_fun, _}), do: true
  def is_f_fun(_), do: false

  @doc "Returns true if value is f_prop variant"
  @spec is_f_prop(t()) :: boolean()
  def is_f_prop({:f_prop, _}), do: true
  def is_f_prop(_), do: false

  @doc "Extracts value from f_var variant, returns {:ok, value} or :error"
  @spec get_f_var_value(t()) :: {:ok, {term(), term()}} | :error
  def get_f_var_value({:f_var, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_f_var_value(_), do: :error

  @doc "Extracts value from f_fun variant, returns {:ok, value} or :error"
  @spec get_f_fun_value(t()) :: {:ok, term()} | :error
  def get_f_fun_value({:f_fun, value}), do: {:ok, value}
  def get_f_fun_value(_), do: :error

  @doc "Extracts value from f_prop variant, returns {:ok, value} or :error"
  @spec get_f_prop_value(t()) :: {:ok, {term(), term(), term(), term()}} | :error
  def get_f_prop_value({:f_prop, arg0, arg1, arg2, arg3}), do: {:ok, {arg0, arg1, arg2, arg3}}
  def get_f_prop_value(_), do: :error

end
