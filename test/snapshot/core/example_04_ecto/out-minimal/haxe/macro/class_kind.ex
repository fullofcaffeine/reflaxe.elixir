defmodule ClassKind do
  @moduledoc """
  ClassKind enum generated from Haxe
  
  
  	Represents the kind of a class.
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :k_normal |
    {:k_type_parameter, term()} |
    {:k_module_fields, term()} |
    {:k_expr, term()} |
    :k_generic |
    {:k_generic_instance, term(), term()} |
    :k_macro_type |
    {:k_abstract_impl, term()} |
    :k_generic_build

  @doc "Creates k_normal enum value"
  @spec k_normal() :: :k_normal
  def k_normal(), do: :k_normal

  @doc """
  Creates k_type_parameter enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec k_type_parameter(term()) :: {:k_type_parameter, term()}
  def k_type_parameter(arg0) do
    {:k_type_parameter, arg0}
  end

  @doc """
  Creates k_module_fields enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec k_module_fields(term()) :: {:k_module_fields, term()}
  def k_module_fields(arg0) do
    {:k_module_fields, arg0}
  end

  @doc """
  Creates k_expr enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec k_expr(term()) :: {:k_expr, term()}
  def k_expr(arg0) do
    {:k_expr, arg0}
  end

  @doc "Creates k_generic enum value"
  @spec k_generic() :: :k_generic
  def k_generic(), do: :k_generic

  @doc """
  Creates k_generic_instance enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec k_generic_instance(term(), term()) :: {:k_generic_instance, term(), term()}
  def k_generic_instance(arg0, arg1) do
    {:k_generic_instance, arg0, arg1}
  end

  @doc "Creates k_macro_type enum value"
  @spec k_macro_type() :: :k_macro_type
  def k_macro_type(), do: :k_macro_type

  @doc """
  Creates k_abstract_impl enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec k_abstract_impl(term()) :: {:k_abstract_impl, term()}
  def k_abstract_impl(arg0) do
    {:k_abstract_impl, arg0}
  end

  @doc "Creates k_generic_build enum value"
  @spec k_generic_build() :: :k_generic_build
  def k_generic_build(), do: :k_generic_build

  # Predicate functions for pattern matching
  @doc "Returns true if value is k_normal variant"
  @spec is_k_normal(t()) :: boolean()
  def is_k_normal(:k_normal), do: true
  def is_k_normal(_), do: false

  @doc "Returns true if value is k_type_parameter variant"
  @spec is_k_type_parameter(t()) :: boolean()
  def is_k_type_parameter({:k_type_parameter, _}), do: true
  def is_k_type_parameter(_), do: false

  @doc "Returns true if value is k_module_fields variant"
  @spec is_k_module_fields(t()) :: boolean()
  def is_k_module_fields({:k_module_fields, _}), do: true
  def is_k_module_fields(_), do: false

  @doc "Returns true if value is k_expr variant"
  @spec is_k_expr(t()) :: boolean()
  def is_k_expr({:k_expr, _}), do: true
  def is_k_expr(_), do: false

  @doc "Returns true if value is k_generic variant"
  @spec is_k_generic(t()) :: boolean()
  def is_k_generic(:k_generic), do: true
  def is_k_generic(_), do: false

  @doc "Returns true if value is k_generic_instance variant"
  @spec is_k_generic_instance(t()) :: boolean()
  def is_k_generic_instance({:k_generic_instance, _}), do: true
  def is_k_generic_instance(_), do: false

  @doc "Returns true if value is k_macro_type variant"
  @spec is_k_macro_type(t()) :: boolean()
  def is_k_macro_type(:k_macro_type), do: true
  def is_k_macro_type(_), do: false

  @doc "Returns true if value is k_abstract_impl variant"
  @spec is_k_abstract_impl(t()) :: boolean()
  def is_k_abstract_impl({:k_abstract_impl, _}), do: true
  def is_k_abstract_impl(_), do: false

  @doc "Returns true if value is k_generic_build variant"
  @spec is_k_generic_build(t()) :: boolean()
  def is_k_generic_build(:k_generic_build), do: true
  def is_k_generic_build(_), do: false

  @doc "Extracts value from k_type_parameter variant, returns {:ok, value} or :error"
  @spec get_k_type_parameter_value(t()) :: {:ok, term()} | :error
  def get_k_type_parameter_value({:k_type_parameter, value}), do: {:ok, value}
  def get_k_type_parameter_value(_), do: :error

  @doc "Extracts value from k_module_fields variant, returns {:ok, value} or :error"
  @spec get_k_module_fields_value(t()) :: {:ok, term()} | :error
  def get_k_module_fields_value({:k_module_fields, value}), do: {:ok, value}
  def get_k_module_fields_value(_), do: :error

  @doc "Extracts value from k_expr variant, returns {:ok, value} or :error"
  @spec get_k_expr_value(t()) :: {:ok, term()} | :error
  def get_k_expr_value({:k_expr, value}), do: {:ok, value}
  def get_k_expr_value(_), do: :error

  @doc "Extracts value from k_generic_instance variant, returns {:ok, value} or :error"
  @spec get_k_generic_instance_value(t()) :: {:ok, {term(), term()}} | :error
  def get_k_generic_instance_value({:k_generic_instance, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_k_generic_instance_value(_), do: :error

  @doc "Extracts value from k_abstract_impl variant, returns {:ok, value} or :error"
  @spec get_k_abstract_impl_value(t()) :: {:ok, term()} | :error
  def get_k_abstract_impl_value({:k_abstract_impl, value}), do: {:ok, value}
  def get_k_abstract_impl_value(_), do: :error

end
