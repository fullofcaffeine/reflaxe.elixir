defmodule ValueType do
  @moduledoc """
  ValueType enum generated from Haxe
  
  
	The different possible runtime types of a value.

  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :t_unknown |
    :t_object |
    :t_null |
    :t_int |
    :t_function |
    :t_float |
    {:t_enum, term()} |
    {:t_class, term()} |
    :t_bool

  @doc "Creates t_unknown enum value"
  @spec t_unknown() :: :t_unknown
  def t_unknown(), do: :t_unknown

  @doc "Creates t_object enum value"
  @spec t_object() :: :t_object
  def t_object(), do: :t_object

  @doc "Creates t_null enum value"
  @spec t_null() :: :t_null
  def t_null(), do: :t_null

  @doc "Creates t_int enum value"
  @spec t_int() :: :t_int
  def t_int(), do: :t_int

  @doc "Creates t_function enum value"
  @spec t_function() :: :t_function
  def t_function(), do: :t_function

  @doc "Creates t_float enum value"
  @spec t_float() :: :t_float
  def t_float(), do: :t_float

  @doc """
  Creates t_enum enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_enum(term()) :: {:t_enum, term()}
  def t_enum(arg0) do
    {:t_enum, arg0}
  end

  @doc """
  Creates t_class enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_class(term()) :: {:t_class, term()}
  def t_class(arg0) do
    {:t_class, arg0}
  end

  @doc "Creates t_bool enum value"
  @spec t_bool() :: :t_bool
  def t_bool(), do: :t_bool

  # Predicate functions for pattern matching
  @doc "Returns true if value is t_unknown variant"
  @spec is_t_unknown(t()) :: boolean()
  def is_t_unknown(:t_unknown), do: true
  def is_t_unknown(_), do: false

  @doc "Returns true if value is t_object variant"
  @spec is_t_object(t()) :: boolean()
  def is_t_object(:t_object), do: true
  def is_t_object(_), do: false

  @doc "Returns true if value is t_null variant"
  @spec is_t_null(t()) :: boolean()
  def is_t_null(:t_null), do: true
  def is_t_null(_), do: false

  @doc "Returns true if value is t_int variant"
  @spec is_t_int(t()) :: boolean()
  def is_t_int(:t_int), do: true
  def is_t_int(_), do: false

  @doc "Returns true if value is t_function variant"
  @spec is_t_function(t()) :: boolean()
  def is_t_function(:t_function), do: true
  def is_t_function(_), do: false

  @doc "Returns true if value is t_float variant"
  @spec is_t_float(t()) :: boolean()
  def is_t_float(:t_float), do: true
  def is_t_float(_), do: false

  @doc "Returns true if value is t_enum variant"
  @spec is_t_enum(t()) :: boolean()
  def is_t_enum({:t_enum, _}), do: true
  def is_t_enum(_), do: false

  @doc "Returns true if value is t_class variant"
  @spec is_t_class(t()) :: boolean()
  def is_t_class({:t_class, _}), do: true
  def is_t_class(_), do: false

  @doc "Returns true if value is t_bool variant"
  @spec is_t_bool(t()) :: boolean()
  def is_t_bool(:t_bool), do: true
  def is_t_bool(_), do: false

  @doc "Extracts value from t_enum variant, returns {:ok, value} or :error"
  @spec get_t_enum_value(t()) :: {:ok, term()} | :error
  def get_t_enum_value({:t_enum, value}), do: {:ok, value}
  def get_t_enum_value(_), do: :error

  @doc "Extracts value from t_class variant, returns {:ok, value} or :error"
  @spec get_t_class_value(t()) :: {:ok, term()} | :error
  def get_t_class_value({:t_class, value}), do: {:ok, value}
  def get_t_class_value(_), do: :error

end
