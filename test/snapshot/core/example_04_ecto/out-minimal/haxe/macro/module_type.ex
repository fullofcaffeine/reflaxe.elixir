defmodule ModuleType do
  @moduledoc """
  ModuleType enum generated from Haxe
  
  
  	Represents a module type. These are the types that can be declared in a Haxe
  	module and which are passed to the generators (except `TTypeDecl`).
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:t_class_decl, term()} |
    {:t_enum_decl, term()} |
    {:t_type_decl, term()} |
    {:t_abstract, term()}

  @doc """
  Creates t_class_decl enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_class_decl(term()) :: {:t_class_decl, term()}
  def t_class_decl(arg0) do
    {:t_class_decl, arg0}
  end

  @doc """
  Creates t_enum_decl enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_enum_decl(term()) :: {:t_enum_decl, term()}
  def t_enum_decl(arg0) do
    {:t_enum_decl, arg0}
  end

  @doc """
  Creates t_type_decl enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_type_decl(term()) :: {:t_type_decl, term()}
  def t_type_decl(arg0) do
    {:t_type_decl, arg0}
  end

  @doc """
  Creates t_abstract enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_abstract(term()) :: {:t_abstract, term()}
  def t_abstract(arg0) do
    {:t_abstract, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is t_class_decl variant"
  @spec is_t_class_decl(t()) :: boolean()
  def is_t_class_decl({:t_class_decl, _}), do: true
  def is_t_class_decl(_), do: false

  @doc "Returns true if value is t_enum_decl variant"
  @spec is_t_enum_decl(t()) :: boolean()
  def is_t_enum_decl({:t_enum_decl, _}), do: true
  def is_t_enum_decl(_), do: false

  @doc "Returns true if value is t_type_decl variant"
  @spec is_t_type_decl(t()) :: boolean()
  def is_t_type_decl({:t_type_decl, _}), do: true
  def is_t_type_decl(_), do: false

  @doc "Returns true if value is t_abstract variant"
  @spec is_t_abstract(t()) :: boolean()
  def is_t_abstract({:t_abstract, _}), do: true
  def is_t_abstract(_), do: false

  @doc "Extracts value from t_class_decl variant, returns {:ok, value} or :error"
  @spec get_t_class_decl_value(t()) :: {:ok, term()} | :error
  def get_t_class_decl_value({:t_class_decl, value}), do: {:ok, value}
  def get_t_class_decl_value(_), do: :error

  @doc "Extracts value from t_enum_decl variant, returns {:ok, value} or :error"
  @spec get_t_enum_decl_value(t()) :: {:ok, term()} | :error
  def get_t_enum_decl_value({:t_enum_decl, value}), do: {:ok, value}
  def get_t_enum_decl_value(_), do: :error

  @doc "Extracts value from t_type_decl variant, returns {:ok, value} or :error"
  @spec get_t_type_decl_value(t()) :: {:ok, term()} | :error
  def get_t_type_decl_value({:t_type_decl, value}), do: {:ok, value}
  def get_t_type_decl_value(_), do: :error

  @doc "Extracts value from t_abstract variant, returns {:ok, value} or :error"
  @spec get_t_abstract_value(t()) :: {:ok, term()} | :error
  def get_t_abstract_value({:t_abstract, value}), do: {:ok, value}
  def get_t_abstract_value(_), do: :error

end
