defmodule TConstant do
  @moduledoc """
  TConstant enum generated from Haxe
  
  
  	Represents typed constant.
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:t_int, term()} |
    {:t_float, term()} |
    {:t_string, term()} |
    {:t_bool, term()} |
    :t_null |
    :t_this |
    :t_super

  @doc """
  Creates t_int enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_int(term()) :: {:t_int, term()}
  def t_int(arg0) do
    {:t_int, arg0}
  end

  @doc """
  Creates t_float enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_float(term()) :: {:t_float, term()}
  def t_float(arg0) do
    {:t_float, arg0}
  end

  @doc """
  Creates t_string enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_string(term()) :: {:t_string, term()}
  def t_string(arg0) do
    {:t_string, arg0}
  end

  @doc """
  Creates t_bool enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_bool(term()) :: {:t_bool, term()}
  def t_bool(arg0) do
    {:t_bool, arg0}
  end

  @doc "Creates t_null enum value"
  @spec t_null() :: :t_null
  def t_null(), do: :t_null

  @doc "Creates t_this enum value"
  @spec t_this() :: :t_this
  def t_this(), do: :t_this

  @doc "Creates t_super enum value"
  @spec t_super() :: :t_super
  def t_super(), do: :t_super

  # Predicate functions for pattern matching
  @doc "Returns true if value is t_int variant"
  @spec is_t_int(t()) :: boolean()
  def is_t_int({:t_int, _}), do: true
  def is_t_int(_), do: false

  @doc "Returns true if value is t_float variant"
  @spec is_t_float(t()) :: boolean()
  def is_t_float({:t_float, _}), do: true
  def is_t_float(_), do: false

  @doc "Returns true if value is t_string variant"
  @spec is_t_string(t()) :: boolean()
  def is_t_string({:t_string, _}), do: true
  def is_t_string(_), do: false

  @doc "Returns true if value is t_bool variant"
  @spec is_t_bool(t()) :: boolean()
  def is_t_bool({:t_bool, _}), do: true
  def is_t_bool(_), do: false

  @doc "Returns true if value is t_null variant"
  @spec is_t_null(t()) :: boolean()
  def is_t_null(:t_null), do: true
  def is_t_null(_), do: false

  @doc "Returns true if value is t_this variant"
  @spec is_t_this(t()) :: boolean()
  def is_t_this(:t_this), do: true
  def is_t_this(_), do: false

  @doc "Returns true if value is t_super variant"
  @spec is_t_super(t()) :: boolean()
  def is_t_super(:t_super), do: true
  def is_t_super(_), do: false

  @doc "Extracts value from t_int variant, returns {:ok, value} or :error"
  @spec get_t_int_value(t()) :: {:ok, term()} | :error
  def get_t_int_value({:t_int, value}), do: {:ok, value}
  def get_t_int_value(_), do: :error

  @doc "Extracts value from t_float variant, returns {:ok, value} or :error"
  @spec get_t_float_value(t()) :: {:ok, term()} | :error
  def get_t_float_value({:t_float, value}), do: {:ok, value}
  def get_t_float_value(_), do: :error

  @doc "Extracts value from t_string variant, returns {:ok, value} or :error"
  @spec get_t_string_value(t()) :: {:ok, term()} | :error
  def get_t_string_value({:t_string, value}), do: {:ok, value}
  def get_t_string_value(_), do: :error

  @doc "Extracts value from t_bool variant, returns {:ok, value} or :error"
  @spec get_t_bool_value(t()) :: {:ok, term()} | :error
  def get_t_bool_value({:t_bool, value}), do: {:ok, value}
  def get_t_bool_value(_), do: :error

end
