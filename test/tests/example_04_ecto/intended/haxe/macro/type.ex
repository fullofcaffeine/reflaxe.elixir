defmodule Type do
  @moduledoc """
  Type enum generated from Haxe
  
  
  	Represents a type.
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:t_mono, term()} |
    {:t_enum, term(), term()} |
    {:t_inst, term(), term()} |
    {:t_type, term(), term()} |
    {:t_fun, term(), term()} |
    {:t_anonymous, term()} |
    {:t_dynamic, term()} |
    {:t_lazy, term()} |
    {:t_abstract, term(), term()}

  @doc """
  Creates t_mono enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_mono(term()) :: {:t_mono, term()}
  def t_mono(arg0) do
    {:t_mono, arg0}
  end

  @doc """
  Creates t_enum enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_enum(term(), term()) :: {:t_enum, term(), term()}
  def t_enum(arg0, arg1) do
    {:t_enum, arg0, arg1}
  end

  @doc """
  Creates t_inst enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_inst(term(), term()) :: {:t_inst, term(), term()}
  def t_inst(arg0, arg1) do
    {:t_inst, arg0, arg1}
  end

  @doc """
  Creates t_type enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_type(term(), term()) :: {:t_type, term(), term()}
  def t_type(arg0, arg1) do
    {:t_type, arg0, arg1}
  end

  @doc """
  Creates t_fun enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_fun(term(), term()) :: {:t_fun, term(), term()}
  def t_fun(arg0, arg1) do
    {:t_fun, arg0, arg1}
  end

  @doc """
  Creates t_anonymous enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_anonymous(term()) :: {:t_anonymous, term()}
  def t_anonymous(arg0) do
    {:t_anonymous, arg0}
  end

  @doc """
  Creates t_dynamic enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_dynamic(term()) :: {:t_dynamic, term()}
  def t_dynamic(arg0) do
    {:t_dynamic, arg0}
  end

  @doc """
  Creates t_lazy enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_lazy(term()) :: {:t_lazy, term()}
  def t_lazy(arg0) do
    {:t_lazy, arg0}
  end

  @doc """
  Creates t_abstract enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_abstract(term(), term()) :: {:t_abstract, term(), term()}
  def t_abstract(arg0, arg1) do
    {:t_abstract, arg0, arg1}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is t_mono variant"
  @spec is_t_mono(t()) :: boolean()
  def is_t_mono({:t_mono, _}), do: true
  def is_t_mono(_), do: false

  @doc "Returns true if value is t_enum variant"
  @spec is_t_enum(t()) :: boolean()
  def is_t_enum({:t_enum, _}), do: true
  def is_t_enum(_), do: false

  @doc "Returns true if value is t_inst variant"
  @spec is_t_inst(t()) :: boolean()
  def is_t_inst({:t_inst, _}), do: true
  def is_t_inst(_), do: false

  @doc "Returns true if value is t_type variant"
  @spec is_t_type(t()) :: boolean()
  def is_t_type({:t_type, _}), do: true
  def is_t_type(_), do: false

  @doc "Returns true if value is t_fun variant"
  @spec is_t_fun(t()) :: boolean()
  def is_t_fun({:t_fun, _}), do: true
  def is_t_fun(_), do: false

  @doc "Returns true if value is t_anonymous variant"
  @spec is_t_anonymous(t()) :: boolean()
  def is_t_anonymous({:t_anonymous, _}), do: true
  def is_t_anonymous(_), do: false

  @doc "Returns true if value is t_dynamic variant"
  @spec is_t_dynamic(t()) :: boolean()
  def is_t_dynamic({:t_dynamic, _}), do: true
  def is_t_dynamic(_), do: false

  @doc "Returns true if value is t_lazy variant"
  @spec is_t_lazy(t()) :: boolean()
  def is_t_lazy({:t_lazy, _}), do: true
  def is_t_lazy(_), do: false

  @doc "Returns true if value is t_abstract variant"
  @spec is_t_abstract(t()) :: boolean()
  def is_t_abstract({:t_abstract, _}), do: true
  def is_t_abstract(_), do: false

  @doc "Extracts value from t_mono variant, returns {:ok, value} or :error"
  @spec get_t_mono_value(t()) :: {:ok, term()} | :error
  def get_t_mono_value({:t_mono, value}), do: {:ok, value}
  def get_t_mono_value(_), do: :error

  @doc "Extracts value from t_enum variant, returns {:ok, value} or :error"
  @spec get_t_enum_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_enum_value({:t_enum, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_enum_value(_), do: :error

  @doc "Extracts value from t_inst variant, returns {:ok, value} or :error"
  @spec get_t_inst_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_inst_value({:t_inst, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_inst_value(_), do: :error

  @doc "Extracts value from t_type variant, returns {:ok, value} or :error"
  @spec get_t_type_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_type_value({:t_type, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_type_value(_), do: :error

  @doc "Extracts value from t_fun variant, returns {:ok, value} or :error"
  @spec get_t_fun_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_fun_value({:t_fun, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_fun_value(_), do: :error

  @doc "Extracts value from t_anonymous variant, returns {:ok, value} or :error"
  @spec get_t_anonymous_value(t()) :: {:ok, term()} | :error
  def get_t_anonymous_value({:t_anonymous, value}), do: {:ok, value}
  def get_t_anonymous_value(_), do: :error

  @doc "Extracts value from t_dynamic variant, returns {:ok, value} or :error"
  @spec get_t_dynamic_value(t()) :: {:ok, term()} | :error
  def get_t_dynamic_value({:t_dynamic, value}), do: {:ok, value}
  def get_t_dynamic_value(_), do: :error

  @doc "Extracts value from t_lazy variant, returns {:ok, value} or :error"
  @spec get_t_lazy_value(t()) :: {:ok, term()} | :error
  def get_t_lazy_value({:t_lazy, value}), do: {:ok, value}
  def get_t_lazy_value(_), do: :error

  @doc "Extracts value from t_abstract variant, returns {:ok, value} or :error"
  @spec get_t_abstract_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_abstract_value({:t_abstract, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_abstract_value(_), do: :error

end
