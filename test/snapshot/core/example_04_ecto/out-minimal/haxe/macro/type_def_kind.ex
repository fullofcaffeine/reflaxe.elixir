defmodule TypeDefKind do
  @moduledoc """
  TypeDefKind enum generated from Haxe
  
  
  	Represents a type definition kind.
  
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :t_d_enum |
    :t_d_structure |
    {:t_d_class, term(), term(), term(), term(), term()} |
    {:t_d_alias, term()} |
    {:t_d_abstract, term(), term(), term(), term()} |
    {:t_d_field, term(), term()}

  @doc "Creates t_d_enum enum value"
  @spec t_d_enum() :: :t_d_enum
  def t_d_enum(), do: :t_d_enum

  @doc "Creates t_d_structure enum value"
  @spec t_d_structure() :: :t_d_structure
  def t_d_structure(), do: :t_d_structure

  @doc """
  Creates t_d_class enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
    - `arg3`: term()
    - `arg4`: term()
  """
  @spec t_d_class(term(), term(), term(), term(), term()) :: {:t_d_class, term(), term(), term(), term(), term()}
  def t_d_class(arg0, arg1, arg2, arg3, arg4) do
    {:t_d_class, arg0, arg1, arg2, arg3, arg4}
  end

  @doc """
  Creates t_d_alias enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_d_alias(term()) :: {:t_d_alias, term()}
  def t_d_alias(arg0) do
    {:t_d_alias, arg0}
  end

  @doc """
  Creates t_d_abstract enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
    - `arg3`: term()
  """
  @spec t_d_abstract(term(), term(), term(), term()) :: {:t_d_abstract, term(), term(), term(), term()}
  def t_d_abstract(arg0, arg1, arg2, arg3) do
    {:t_d_abstract, arg0, arg1, arg2, arg3}
  end

  @doc """
  Creates t_d_field enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_d_field(term(), term()) :: {:t_d_field, term(), term()}
  def t_d_field(arg0, arg1) do
    {:t_d_field, arg0, arg1}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is t_d_enum variant"
  @spec is_t_d_enum(t()) :: boolean()
  def is_t_d_enum(:t_d_enum), do: true
  def is_t_d_enum(_), do: false

  @doc "Returns true if value is t_d_structure variant"
  @spec is_t_d_structure(t()) :: boolean()
  def is_t_d_structure(:t_d_structure), do: true
  def is_t_d_structure(_), do: false

  @doc "Returns true if value is t_d_class variant"
  @spec is_t_d_class(t()) :: boolean()
  def is_t_d_class({:t_d_class, _}), do: true
  def is_t_d_class(_), do: false

  @doc "Returns true if value is t_d_alias variant"
  @spec is_t_d_alias(t()) :: boolean()
  def is_t_d_alias({:t_d_alias, _}), do: true
  def is_t_d_alias(_), do: false

  @doc "Returns true if value is t_d_abstract variant"
  @spec is_t_d_abstract(t()) :: boolean()
  def is_t_d_abstract({:t_d_abstract, _}), do: true
  def is_t_d_abstract(_), do: false

  @doc "Returns true if value is t_d_field variant"
  @spec is_t_d_field(t()) :: boolean()
  def is_t_d_field({:t_d_field, _}), do: true
  def is_t_d_field(_), do: false

  @doc "Extracts value from t_d_class variant, returns {:ok, value} or :error"
  @spec get_t_d_class_value(t()) :: {:ok, {term(), term(), term(), term(), term()}} | :error
  def get_t_d_class_value({:t_d_class, arg0, arg1, arg2, arg3, arg4}), do: {:ok, {arg0, arg1, arg2, arg3, arg4}}
  def get_t_d_class_value(_), do: :error

  @doc "Extracts value from t_d_alias variant, returns {:ok, value} or :error"
  @spec get_t_d_alias_value(t()) :: {:ok, term()} | :error
  def get_t_d_alias_value({:t_d_alias, value}), do: {:ok, value}
  def get_t_d_alias_value(_), do: :error

  @doc "Extracts value from t_d_abstract variant, returns {:ok, value} or :error"
  @spec get_t_d_abstract_value(t()) :: {:ok, {term(), term(), term(), term()}} | :error
  def get_t_d_abstract_value({:t_d_abstract, arg0, arg1, arg2, arg3}), do: {:ok, {arg0, arg1, arg2, arg3}}
  def get_t_d_abstract_value(_), do: :error

  @doc "Extracts value from t_d_field variant, returns {:ok, value} or :error"
  @spec get_t_d_field_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_d_field_value({:t_d_field, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_d_field_value(_), do: :error

end
