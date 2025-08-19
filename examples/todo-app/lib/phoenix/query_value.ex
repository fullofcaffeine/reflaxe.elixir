defmodule QueryValue do
  @moduledoc """
  QueryValue enum generated from Haxe
  
  
   * Query value types for parameterized queries
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:string, term()} |
    {:integer, term()} |
    {:float, term()} |
    {:boolean, term()} |
    {:date, term()} |
    {:binary, term()} |
    {:array, term()} |
    {:field, term()} |
    {:fragment, term(), term()}

  @doc """
  Creates string enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec string(term()) :: {:string, term()}
  def string(arg0) do
    {:string, arg0}
  end

  @doc """
  Creates integer enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec integer(term()) :: {:integer, term()}
  def integer(arg0) do
    {:integer, arg0}
  end

  @doc """
  Creates float enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec float(term()) :: {:float, term()}
  def float(arg0) do
    {:float, arg0}
  end

  @doc """
  Creates boolean enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec boolean(term()) :: {:boolean, term()}
  def boolean(arg0) do
    {:boolean, arg0}
  end

  @doc """
  Creates date enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec date(term()) :: {:date, term()}
  def date(arg0) do
    {:date, arg0}
  end

  @doc """
  Creates binary enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec binary(term()) :: {:binary, term()}
  def binary(arg0) do
    {:binary, arg0}
  end

  @doc """
  Creates array enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec array(term()) :: {:array, term()}
  def array(arg0) do
    {:array, arg0}
  end

  @doc """
  Creates field enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec field(term()) :: {:field, term()}
  def field(arg0) do
    {:field, arg0}
  end

  @doc """
  Creates fragment enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec fragment(term(), term()) :: {:fragment, term(), term()}
  def fragment(arg0, arg1) do
    {:fragment, arg0, arg1}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is string variant"
  @spec is_string(t()) :: boolean()
  def is_string({:string, _}), do: true
  def is_string(_), do: false

  @doc "Returns true if value is integer variant"
  @spec is_integer(t()) :: boolean()
  def is_integer({:integer, _}), do: true
  def is_integer(_), do: false

  @doc "Returns true if value is float variant"
  @spec is_float(t()) :: boolean()
  def is_float({:float, _}), do: true
  def is_float(_), do: false

  @doc "Returns true if value is boolean variant"
  @spec is_boolean(t()) :: boolean()
  def is_boolean({:boolean, _}), do: true
  def is_boolean(_), do: false

  @doc "Returns true if value is date variant"
  @spec is_date(t()) :: boolean()
  def is_date({:date, _}), do: true
  def is_date(_), do: false

  @doc "Returns true if value is binary variant"
  @spec is_binary(t()) :: boolean()
  def is_binary({:binary, _}), do: true
  def is_binary(_), do: false

  @doc "Returns true if value is array variant"
  @spec is_array(t()) :: boolean()
  def is_array({:array, _}), do: true
  def is_array(_), do: false

  @doc "Returns true if value is field variant"
  @spec is_field(t()) :: boolean()
  def is_field({:field, _}), do: true
  def is_field(_), do: false

  @doc "Returns true if value is fragment variant"
  @spec is_fragment(t()) :: boolean()
  def is_fragment({:fragment, _}), do: true
  def is_fragment(_), do: false

  @doc "Extracts value from string variant, returns {:ok, value} or :error"
  @spec get_string_value(t()) :: {:ok, term()} | :error
  def get_string_value({:string, value}), do: {:ok, value}
  def get_string_value(_), do: :error

  @doc "Extracts value from integer variant, returns {:ok, value} or :error"
  @spec get_integer_value(t()) :: {:ok, term()} | :error
  def get_integer_value({:integer, value}), do: {:ok, value}
  def get_integer_value(_), do: :error

  @doc "Extracts value from float variant, returns {:ok, value} or :error"
  @spec get_float_value(t()) :: {:ok, term()} | :error
  def get_float_value({:float, value}), do: {:ok, value}
  def get_float_value(_), do: :error

  @doc "Extracts value from boolean variant, returns {:ok, value} or :error"
  @spec get_boolean_value(t()) :: {:ok, term()} | :error
  def get_boolean_value({:boolean, value}), do: {:ok, value}
  def get_boolean_value(_), do: :error

  @doc "Extracts value from date variant, returns {:ok, value} or :error"
  @spec get_date_value(t()) :: {:ok, term()} | :error
  def get_date_value({:date, value}), do: {:ok, value}
  def get_date_value(_), do: :error

  @doc "Extracts value from binary variant, returns {:ok, value} or :error"
  @spec get_binary_value(t()) :: {:ok, term()} | :error
  def get_binary_value({:binary, value}), do: {:ok, value}
  def get_binary_value(_), do: :error

  @doc "Extracts value from array variant, returns {:ok, value} or :error"
  @spec get_array_value(t()) :: {:ok, term()} | :error
  def get_array_value({:array, value}), do: {:ok, value}
  def get_array_value(_), do: :error

  @doc "Extracts value from field variant, returns {:ok, value} or :error"
  @spec get_field_value(t()) :: {:ok, term()} | :error
  def get_field_value({:field, value}), do: {:ok, value}
  def get_field_value(_), do: :error

  @doc "Extracts value from fragment variant, returns {:ok, value} or :error"
  @spec get_fragment_value(t()) :: {:ok, {term(), term()}} | :error
  def get_fragment_value({:fragment, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_fragment_value(_), do: :error

end
