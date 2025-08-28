defmodule FieldAccess do
  @moduledoc """
  FieldAccess enum generated from Haxe
  
  
  	Represents the kind of field access in the typed AST.
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:f_instance, term(), term(), term()} |
    {:f_static, term(), term()} |
    {:f_anon, term()} |
    {:f_dynamic, term()} |
    {:f_closure, term(), term()} |
    {:f_enum, term(), term()}

  @doc """
  Creates f_instance enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec f_instance(term(), term(), term()) :: {:f_instance, term(), term(), term()}
  def f_instance(arg0, arg1, arg2) do
    {:f_instance, arg0, arg1, arg2}
  end

  @doc """
  Creates f_static enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec f_static(term(), term()) :: {:f_static, term(), term()}
  def f_static(arg0, arg1) do
    {:f_static, arg0, arg1}
  end

  @doc """
  Creates f_anon enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec f_anon(term()) :: {:f_anon, term()}
  def f_anon(arg0) do
    {:f_anon, arg0}
  end

  @doc """
  Creates f_dynamic enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec f_dynamic(term()) :: {:f_dynamic, term()}
  def f_dynamic(arg0) do
    {:f_dynamic, arg0}
  end

  @doc """
  Creates f_closure enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec f_closure(term(), term()) :: {:f_closure, term(), term()}
  def f_closure(arg0, arg1) do
    {:f_closure, arg0, arg1}
  end

  @doc """
  Creates f_enum enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec f_enum(term(), term()) :: {:f_enum, term(), term()}
  def f_enum(arg0, arg1) do
    {:f_enum, arg0, arg1}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is f_instance variant"
  @spec is_f_instance(t()) :: boolean()
  def is_f_instance({:f_instance, _}), do: true
  def is_f_instance(_), do: false

  @doc "Returns true if value is f_static variant"
  @spec is_f_static(t()) :: boolean()
  def is_f_static({:f_static, _}), do: true
  def is_f_static(_), do: false

  @doc "Returns true if value is f_anon variant"
  @spec is_f_anon(t()) :: boolean()
  def is_f_anon({:f_anon, _}), do: true
  def is_f_anon(_), do: false

  @doc "Returns true if value is f_dynamic variant"
  @spec is_f_dynamic(t()) :: boolean()
  def is_f_dynamic({:f_dynamic, _}), do: true
  def is_f_dynamic(_), do: false

  @doc "Returns true if value is f_closure variant"
  @spec is_f_closure(t()) :: boolean()
  def is_f_closure({:f_closure, _}), do: true
  def is_f_closure(_), do: false

  @doc "Returns true if value is f_enum variant"
  @spec is_f_enum(t()) :: boolean()
  def is_f_enum({:f_enum, _}), do: true
  def is_f_enum(_), do: false

  @doc "Extracts value from f_instance variant, returns {:ok, value} or :error"
  @spec get_f_instance_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_f_instance_value({:f_instance, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_f_instance_value(_), do: :error

  @doc "Extracts value from f_static variant, returns {:ok, value} or :error"
  @spec get_f_static_value(t()) :: {:ok, {term(), term()}} | :error
  def get_f_static_value({:f_static, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_f_static_value(_), do: :error

  @doc "Extracts value from f_anon variant, returns {:ok, value} or :error"
  @spec get_f_anon_value(t()) :: {:ok, term()} | :error
  def get_f_anon_value({:f_anon, value}), do: {:ok, value}
  def get_f_anon_value(_), do: :error

  @doc "Extracts value from f_dynamic variant, returns {:ok, value} or :error"
  @spec get_f_dynamic_value(t()) :: {:ok, term()} | :error
  def get_f_dynamic_value({:f_dynamic, value}), do: {:ok, value}
  def get_f_dynamic_value(_), do: :error

  @doc "Extracts value from f_closure variant, returns {:ok, value} or :error"
  @spec get_f_closure_value(t()) :: {:ok, {term(), term()}} | :error
  def get_f_closure_value({:f_closure, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_f_closure_value(_), do: :error

  @doc "Extracts value from f_enum variant, returns {:ok, value} or :error"
  @spec get_f_enum_value(t()) :: {:ok, {term(), term()}} | :error
  def get_f_enum_value({:f_enum, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_f_enum_value(_), do: :error

end
