defmodule ChangesetValue do
  @moduledoc """
  ChangesetValue enum generated from Haxe
  
  
 * Valid changeset values - strongly typed
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:string_value, term()} |
    {:int_value, term()} |
    {:float_value, term()} |
    {:bool_value, term()} |
    {:date_value, term()} |
    :null_value |
    {:array_value, term()} |
    {:map_value, term()}

  @doc """
  Creates string_value enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec string_value(term()) :: {:string_value, term()}
  def string_value(arg0) do
    {:string_value, arg0}
  end

  @doc """
  Creates int_value enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec int_value(term()) :: {:int_value, term()}
  def int_value(arg0) do
    {:int_value, arg0}
  end

  @doc """
  Creates float_value enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec float_value(term()) :: {:float_value, term()}
  def float_value(arg0) do
    {:float_value, arg0}
  end

  @doc """
  Creates bool_value enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec bool_value(term()) :: {:bool_value, term()}
  def bool_value(arg0) do
    {:bool_value, arg0}
  end

  @doc """
  Creates date_value enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec date_value(term()) :: {:date_value, term()}
  def date_value(arg0) do
    {:date_value, arg0}
  end

  @doc "Creates null_value enum value"
  @spec null_value() :: :null_value
  def null_value(), do: :null_value

  @doc """
  Creates array_value enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec array_value(term()) :: {:array_value, term()}
  def array_value(arg0) do
    {:array_value, arg0}
  end

  @doc """
  Creates map_value enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec map_value(term()) :: {:map_value, term()}
  def map_value(arg0) do
    {:map_value, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is string_value variant"
  @spec is_string_value(t()) :: boolean()
  def is_string_value({:string_value, _}), do: true
  def is_string_value(_), do: false

  @doc "Returns true if value is int_value variant"
  @spec is_int_value(t()) :: boolean()
  def is_int_value({:int_value, _}), do: true
  def is_int_value(_), do: false

  @doc "Returns true if value is float_value variant"
  @spec is_float_value(t()) :: boolean()
  def is_float_value({:float_value, _}), do: true
  def is_float_value(_), do: false

  @doc "Returns true if value is bool_value variant"
  @spec is_bool_value(t()) :: boolean()
  def is_bool_value({:bool_value, _}), do: true
  def is_bool_value(_), do: false

  @doc "Returns true if value is date_value variant"
  @spec is_date_value(t()) :: boolean()
  def is_date_value({:date_value, _}), do: true
  def is_date_value(_), do: false

  @doc "Returns true if value is null_value variant"
  @spec is_null_value(t()) :: boolean()
  def is_null_value(:null_value), do: true
  def is_null_value(_), do: false

  @doc "Returns true if value is array_value variant"
  @spec is_array_value(t()) :: boolean()
  def is_array_value({:array_value, _}), do: true
  def is_array_value(_), do: false

  @doc "Returns true if value is map_value variant"
  @spec is_map_value(t()) :: boolean()
  def is_map_value({:map_value, _}), do: true
  def is_map_value(_), do: false

  @doc "Extracts value from string_value variant, returns {:ok, value} or :error"
  @spec get_string_value_value(t()) :: {:ok, term()} | :error
  def get_string_value_value({:string_value, value}), do: {:ok, value}
  def get_string_value_value(_), do: :error

  @doc "Extracts value from int_value variant, returns {:ok, value} or :error"
  @spec get_int_value_value(t()) :: {:ok, term()} | :error
  def get_int_value_value({:int_value, value}), do: {:ok, value}
  def get_int_value_value(_), do: :error

  @doc "Extracts value from float_value variant, returns {:ok, value} or :error"
  @spec get_float_value_value(t()) :: {:ok, term()} | :error
  def get_float_value_value({:float_value, value}), do: {:ok, value}
  def get_float_value_value(_), do: :error

  @doc "Extracts value from bool_value variant, returns {:ok, value} or :error"
  @spec get_bool_value_value(t()) :: {:ok, term()} | :error
  def get_bool_value_value({:bool_value, value}), do: {:ok, value}
  def get_bool_value_value(_), do: :error

  @doc "Extracts value from date_value variant, returns {:ok, value} or :error"
  @spec get_date_value_value(t()) :: {:ok, term()} | :error
  def get_date_value_value({:date_value, value}), do: {:ok, value}
  def get_date_value_value(_), do: :error

  @doc "Extracts value from array_value variant, returns {:ok, value} or :error"
  @spec get_array_value_value(t()) :: {:ok, term()} | :error
  def get_array_value_value({:array_value, value}), do: {:ok, value}
  def get_array_value_value(_), do: :error

  @doc "Extracts value from map_value variant, returns {:ok, value} or :error"
  @spec get_map_value_value(t()) :: {:ok, term()} | :error
  def get_map_value_value({:map_value, value}), do: {:ok, value}
  def get_map_value_value(_), do: :error

end
