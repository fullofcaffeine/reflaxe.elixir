defmodule FieldType do
  @moduledoc """
  FieldType enum generated from Haxe
  
  
 * Ecto field types
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :id |
    :binary_id |
    :integer |
    :float |
    :boolean |
    :string |
    :binary |
    :date |
    :time |
    :naive_datetime |
    :utc_datetime |
    :map |
    {:array, term()} |
    :decimal |
    {:custom, term()}

  @doc "Creates id enum value"
  @spec id() :: :id
  def id(), do: :id

  @doc "Creates binary_id enum value"
  @spec binary_id() :: :binary_id
  def binary_id(), do: :binary_id

  @doc "Creates integer enum value"
  @spec integer() :: :integer
  def integer(), do: :integer

  @doc "Creates float enum value"
  @spec float() :: :float
  def float(), do: :float

  @doc "Creates boolean enum value"
  @spec boolean() :: :boolean
  def boolean(), do: :boolean

  @doc "Creates string enum value"
  @spec string() :: :string
  def string(), do: :string

  @doc "Creates binary enum value"
  @spec binary() :: :binary
  def binary(), do: :binary

  @doc "Creates date enum value"
  @spec date() :: :date
  def date(), do: :date

  @doc "Creates time enum value"
  @spec time() :: :time
  def time(), do: :time

  @doc "Creates naive_datetime enum value"
  @spec naive_datetime() :: :naive_datetime
  def naive_datetime(), do: :naive_datetime

  @doc "Creates utc_datetime enum value"
  @spec utc_datetime() :: :utc_datetime
  def utc_datetime(), do: :utc_datetime

  @doc "Creates map enum value"
  @spec map() :: :map
  def map(), do: :map

  @doc """
  Creates array enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec array(term()) :: {:array, term()}
  def array(arg0) do
    {:array, arg0}
  end

  @doc "Creates decimal enum value"
  @spec decimal() :: :decimal
  def decimal(), do: :decimal

  @doc """
  Creates custom enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec custom(term()) :: {:custom, term()}
  def custom(arg0) do
    {:custom, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is id variant"
  @spec is_id(t()) :: boolean()
  def is_id(:id), do: true
  def is_id(_), do: false

  @doc "Returns true if value is binary_id variant"
  @spec is_binary_id(t()) :: boolean()
  def is_binary_id(:binary_id), do: true
  def is_binary_id(_), do: false

  @doc "Returns true if value is integer variant"
  @spec is_integer(t()) :: boolean()
  def is_integer(:integer), do: true
  def is_integer(_), do: false

  @doc "Returns true if value is float variant"
  @spec is_float(t()) :: boolean()
  def is_float(:float), do: true
  def is_float(_), do: false

  @doc "Returns true if value is boolean variant"
  @spec is_boolean(t()) :: boolean()
  def is_boolean(:boolean), do: true
  def is_boolean(_), do: false

  @doc "Returns true if value is string variant"
  @spec is_string(t()) :: boolean()
  def is_string(:string), do: true
  def is_string(_), do: false

  @doc "Returns true if value is binary variant"
  @spec is_binary(t()) :: boolean()
  def is_binary(:binary), do: true
  def is_binary(_), do: false

  @doc "Returns true if value is date variant"
  @spec is_date(t()) :: boolean()
  def is_date(:date), do: true
  def is_date(_), do: false

  @doc "Returns true if value is time variant"
  @spec is_time(t()) :: boolean()
  def is_time(:time), do: true
  def is_time(_), do: false

  @doc "Returns true if value is naive_datetime variant"
  @spec is_naive_datetime(t()) :: boolean()
  def is_naive_datetime(:naive_datetime), do: true
  def is_naive_datetime(_), do: false

  @doc "Returns true if value is utc_datetime variant"
  @spec is_utc_datetime(t()) :: boolean()
  def is_utc_datetime(:utc_datetime), do: true
  def is_utc_datetime(_), do: false

  @doc "Returns true if value is map variant"
  @spec is_map(t()) :: boolean()
  def is_map(:map), do: true
  def is_map(_), do: false

  @doc "Returns true if value is array variant"
  @spec is_array(t()) :: boolean()
  def is_array({:array, _}), do: true
  def is_array(_), do: false

  @doc "Returns true if value is decimal variant"
  @spec is_decimal(t()) :: boolean()
  def is_decimal(:decimal), do: true
  def is_decimal(_), do: false

  @doc "Returns true if value is custom variant"
  @spec is_custom(t()) :: boolean()
  def is_custom({:custom, _}), do: true
  def is_custom(_), do: false

  @doc "Extracts value from array variant, returns {:ok, value} or :error"
  @spec get_array_value(t()) :: {:ok, term()} | :error
  def get_array_value({:array, value}), do: {:ok, value}
  def get_array_value(_), do: :error

  @doc "Extracts value from custom variant, returns {:ok, value} or :error"
  @spec get_custom_value(t()) :: {:ok, term()} | :error
  def get_custom_value({:custom, value}), do: {:ok, value}
  def get_custom_value(_), do: :error

end
