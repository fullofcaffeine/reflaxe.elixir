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


defmodule ComparisonOperator do
  @moduledoc """
  ComparisonOperator enum generated from Haxe
  
  
 * Comparison operators for joins and conditions
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :equal |
    :not_equal |
    :greater_than |
    :greater_than_or_equal |
    :less_than |
    :less_than_or_equal |
    {:in_, term()} |
    {:like, term()} |
    :is_null |
    :is_not_null

  @doc "Creates equal enum value"
  @spec equal() :: :equal
  def equal(), do: :equal

  @doc "Creates not_equal enum value"
  @spec not_equal() :: :not_equal
  def not_equal(), do: :not_equal

  @doc "Creates greater_than enum value"
  @spec greater_than() :: :greater_than
  def greater_than(), do: :greater_than

  @doc "Creates greater_than_or_equal enum value"
  @spec greater_than_or_equal() :: :greater_than_or_equal
  def greater_than_or_equal(), do: :greater_than_or_equal

  @doc "Creates less_than enum value"
  @spec less_than() :: :less_than
  def less_than(), do: :less_than

  @doc "Creates less_than_or_equal enum value"
  @spec less_than_or_equal() :: :less_than_or_equal
  def less_than_or_equal(), do: :less_than_or_equal

  @doc """
  Creates in_ enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec in_(term()) :: {:in_, term()}
  def in_(arg0) do
    {:in_, arg0}
  end

  @doc """
  Creates like enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec like(term()) :: {:like, term()}
  def like(arg0) do
    {:like, arg0}
  end

  @doc "Creates is_null enum value"
  @spec is_null() :: :is_null
  def is_null(), do: :is_null

  @doc "Creates is_not_null enum value"
  @spec is_not_null() :: :is_not_null
  def is_not_null(), do: :is_not_null

  # Predicate functions for pattern matching
  @doc "Returns true if value is equal variant"
  @spec is_equal(t()) :: boolean()
  def is_equal(:equal), do: true
  def is_equal(_), do: false

  @doc "Returns true if value is not_equal variant"
  @spec is_not_equal(t()) :: boolean()
  def is_not_equal(:not_equal), do: true
  def is_not_equal(_), do: false

  @doc "Returns true if value is greater_than variant"
  @spec is_greater_than(t()) :: boolean()
  def is_greater_than(:greater_than), do: true
  def is_greater_than(_), do: false

  @doc "Returns true if value is greater_than_or_equal variant"
  @spec is_greater_than_or_equal(t()) :: boolean()
  def is_greater_than_or_equal(:greater_than_or_equal), do: true
  def is_greater_than_or_equal(_), do: false

  @doc "Returns true if value is less_than variant"
  @spec is_less_than(t()) :: boolean()
  def is_less_than(:less_than), do: true
  def is_less_than(_), do: false

  @doc "Returns true if value is less_than_or_equal variant"
  @spec is_less_than_or_equal(t()) :: boolean()
  def is_less_than_or_equal(:less_than_or_equal), do: true
  def is_less_than_or_equal(_), do: false

  @doc "Returns true if value is in_ variant"
  @spec is_in_(t()) :: boolean()
  def is_in_({:in_, _}), do: true
  def is_in_(_), do: false

  @doc "Returns true if value is like variant"
  @spec is_like(t()) :: boolean()
  def is_like({:like, _}), do: true
  def is_like(_), do: false

  @doc "Returns true if value is is_null variant"
  @spec is_is_null(t()) :: boolean()
  def is_is_null(:is_null), do: true
  def is_is_null(_), do: false

  @doc "Returns true if value is is_not_null variant"
  @spec is_is_not_null(t()) :: boolean()
  def is_is_not_null(:is_not_null), do: true
  def is_is_not_null(_), do: false

  @doc "Extracts value from in_ variant, returns {:ok, value} or :error"
  @spec get_in__value(t()) :: {:ok, term()} | :error
  def get_in__value({:in_, value}), do: {:ok, value}
  def get_in__value(_), do: :error

  @doc "Extracts value from like variant, returns {:ok, value} or :error"
  @spec get_like_value(t()) :: {:ok, term()} | :error
  def get_like_value({:like, value}), do: {:ok, value}
  def get_like_value(_), do: :error

end


defmodule JoinType do
  @moduledoc """
  JoinType enum generated from Haxe
  
  
 * Join type enumeration
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :inner |
    :left |
    :right |
    :full |
    :cross

  @doc "Creates inner enum value"
  @spec inner() :: :inner
  def inner(), do: :inner

  @doc "Creates left enum value"
  @spec left() :: :left
  def left(), do: :left

  @doc "Creates right enum value"
  @spec right() :: :right
  def right(), do: :right

  @doc "Creates full enum value"
  @spec full() :: :full
  def full(), do: :full

  @doc "Creates cross enum value"
  @spec cross() :: :cross
  def cross(), do: :cross

  # Predicate functions for pattern matching
  @doc "Returns true if value is inner variant"
  @spec is_inner(t()) :: boolean()
  def is_inner(:inner), do: true
  def is_inner(_), do: false

  @doc "Returns true if value is left variant"
  @spec is_left(t()) :: boolean()
  def is_left(:left), do: true
  def is_left(_), do: false

  @doc "Returns true if value is right variant"
  @spec is_right(t()) :: boolean()
  def is_right(:right), do: true
  def is_right(_), do: false

  @doc "Returns true if value is full variant"
  @spec is_full(t()) :: boolean()
  def is_full(:full), do: true
  def is_full(_), do: false

  @doc "Returns true if value is cross variant"
  @spec is_cross(t()) :: boolean()
  def is_cross(:cross), do: true
  def is_cross(_), do: false

end


defmodule SortDirection do
  @moduledoc """
  SortDirection enum generated from Haxe
  
  
 * Sort direction for queries
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :asc |
    :desc

  @doc "Creates asc enum value"
  @spec asc() :: :asc
  def asc(), do: :asc

  @doc "Creates desc enum value"
  @spec desc() :: :desc
  def desc(), do: :desc

  # Predicate functions for pattern matching
  @doc "Returns true if value is asc variant"
  @spec is_asc(t()) :: boolean()
  def is_asc(:asc), do: true
  def is_asc(_), do: false

  @doc "Returns true if value is desc variant"
  @spec is_desc(t()) :: boolean()
  def is_desc(:desc), do: true
  def is_desc(_), do: false

end


defmodule NullsPosition do
  @moduledoc """
  NullsPosition enum generated from Haxe
  
  
 * Nulls position in ordering
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :first |
    :last |
    :default

  @doc "Creates first enum value"
  @spec first() :: :first
  def first(), do: :first

  @doc "Creates last enum value"
  @spec last() :: :last
  def last(), do: :last

  @doc "Creates default enum value"
  @spec default() :: :default
  def default(), do: :default

  # Predicate functions for pattern matching
  @doc "Returns true if value is first variant"
  @spec is_first(t()) :: boolean()
  def is_first(:first), do: true
  def is_first(_), do: false

  @doc "Returns true if value is last variant"
  @spec is_last(t()) :: boolean()
  def is_last(:last), do: true
  def is_last(_), do: false

  @doc "Returns true if value is default variant"
  @spec is_default(t()) :: boolean()
  def is_default(:default), do: true
  def is_default(_), do: false

end


defmodule RepoOption do
  @moduledoc """
  RepoOption enum generated from Haxe
  
  
 * Repository operation options - type-safe alternatives to Dynamic
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:timeout, term()} |
    {:log, term()} |
    {:telemetry, term()} |
    {:prefix, term()} |
    {:read_only, term()}

  @doc """
  Creates timeout enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec timeout(term()) :: {:timeout, term()}
  def timeout(arg0) do
    {:timeout, arg0}
  end

  @doc """
  Creates log enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec log(term()) :: {:log, term()}
  def log(arg0) do
    {:log, arg0}
  end

  @doc """
  Creates telemetry enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec telemetry(term()) :: {:telemetry, term()}
  def telemetry(arg0) do
    {:telemetry, arg0}
  end

  @doc """
  Creates prefix enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec prefix(term()) :: {:prefix, term()}
  def prefix(arg0) do
    {:prefix, arg0}
  end

  @doc """
  Creates read_only enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec read_only(term()) :: {:read_only, term()}
  def read_only(arg0) do
    {:read_only, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is timeout variant"
  @spec is_timeout(t()) :: boolean()
  def is_timeout({:timeout, _}), do: true
  def is_timeout(_), do: false

  @doc "Returns true if value is log variant"
  @spec is_log(t()) :: boolean()
  def is_log({:log, _}), do: true
  def is_log(_), do: false

  @doc "Returns true if value is telemetry variant"
  @spec is_telemetry(t()) :: boolean()
  def is_telemetry({:telemetry, _}), do: true
  def is_telemetry(_), do: false

  @doc "Returns true if value is prefix variant"
  @spec is_prefix(t()) :: boolean()
  def is_prefix({:prefix, _}), do: true
  def is_prefix(_), do: false

  @doc "Returns true if value is read_only variant"
  @spec is_read_only(t()) :: boolean()
  def is_read_only({:read_only, _}), do: true
  def is_read_only(_), do: false

  @doc "Extracts value from timeout variant, returns {:ok, value} or :error"
  @spec get_timeout_value(t()) :: {:ok, term()} | :error
  def get_timeout_value({:timeout, value}), do: {:ok, value}
  def get_timeout_value(_), do: :error

  @doc "Extracts value from log variant, returns {:ok, value} or :error"
  @spec get_log_value(t()) :: {:ok, term()} | :error
  def get_log_value({:log, value}), do: {:ok, value}
  def get_log_value(_), do: :error

  @doc "Extracts value from telemetry variant, returns {:ok, value} or :error"
  @spec get_telemetry_value(t()) :: {:ok, term()} | :error
  def get_telemetry_value({:telemetry, value}), do: {:ok, value}
  def get_telemetry_value(_), do: :error

  @doc "Extracts value from prefix variant, returns {:ok, value} or :error"
  @spec get_prefix_value(t()) :: {:ok, term()} | :error
  def get_prefix_value({:prefix, value}), do: {:ok, value}
  def get_prefix_value(_), do: :error

  @doc "Extracts value from read_only variant, returns {:ok, value} or :error"
  @spec get_read_only_value(t()) :: {:ok, term()} | :error
  def get_read_only_value({:read_only, value}), do: {:ok, value}
  def get_read_only_value(_), do: :error

end


defmodule LogLevel do
  @moduledoc """
  LogLevel enum generated from Haxe
  
  
 * Log levels for repository operations
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :debug |
    :info |
    :warning |
    :error

  @doc "Creates debug enum value"
  @spec debug() :: :debug
  def debug(), do: :debug

  @doc "Creates info enum value"
  @spec info() :: :info
  def info(), do: :info

  @doc "Creates warning enum value"
  @spec warning() :: :warning
  def warning(), do: :warning

  @doc "Creates error enum value"
  @spec error() :: :error
  def error(), do: :error

  # Predicate functions for pattern matching
  @doc "Returns true if value is debug variant"
  @spec is_debug(t()) :: boolean()
  def is_debug(:debug), do: true
  def is_debug(_), do: false

  @doc "Returns true if value is info variant"
  @spec is_info(t()) :: boolean()
  def is_info(:info), do: true
  def is_info(_), do: false

  @doc "Returns true if value is warning variant"
  @spec is_warning(t()) :: boolean()
  def is_warning(:warning), do: true
  def is_warning(_), do: false

  @doc "Returns true if value is error variant"
  @spec is_error(t()) :: boolean()
  def is_error(:error), do: true
  def is_error(_), do: false

end


defmodule ChangesetAction do
  @moduledoc """
  ChangesetAction enum generated from Haxe
  
  
 * Changeset actions
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :insert |
    :update |
    :delete |
    :replace |
    :ignore

  @doc "Creates insert enum value"
  @spec insert() :: :insert
  def insert(), do: :insert

  @doc "Creates update enum value"
  @spec update() :: :update
  def update(), do: :update

  @doc "Creates delete enum value"
  @spec delete() :: :delete
  def delete(), do: :delete

  @doc "Creates replace enum value"
  @spec replace() :: :replace
  def replace(), do: :replace

  @doc "Creates ignore enum value"
  @spec ignore() :: :ignore
  def ignore(), do: :ignore

  # Predicate functions for pattern matching
  @doc "Returns true if value is insert variant"
  @spec is_insert(t()) :: boolean()
  def is_insert(:insert), do: true
  def is_insert(_), do: false

  @doc "Returns true if value is update variant"
  @spec is_update(t()) :: boolean()
  def is_update(:update), do: true
  def is_update(_), do: false

  @doc "Returns true if value is delete variant"
  @spec is_delete(t()) :: boolean()
  def is_delete(:delete), do: true
  def is_delete(_), do: false

  @doc "Returns true if value is replace variant"
  @spec is_replace(t()) :: boolean()
  def is_replace(:replace), do: true
  def is_replace(_), do: false

  @doc "Returns true if value is ignore variant"
  @spec is_ignore(t()) :: boolean()
  def is_ignore(:ignore), do: true
  def is_ignore(_), do: false

end


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


defmodule EmbedStrategy do
  @moduledoc """
  EmbedStrategy enum generated from Haxe
  
  
 * Embed strategies
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :replace |
    :append

  @doc "Creates replace enum value"
  @spec replace() :: :replace
  def replace(), do: :replace

  @doc "Creates append enum value"
  @spec append() :: :append
  def append(), do: :append

  # Predicate functions for pattern matching
  @doc "Returns true if value is replace variant"
  @spec is_replace(t()) :: boolean()
  def is_replace(:replace), do: true
  def is_replace(_), do: false

  @doc "Returns true if value is append variant"
  @spec is_append(t()) :: boolean()
  def is_append(:append), do: true
  def is_append(_), do: false

end


defmodule OnDeleteAction do
  @moduledoc """
  OnDeleteAction enum generated from Haxe
  
  
 * On delete actions
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :nothing |
    :restrict |
    :delete_all |
    :nilify_all

  @doc "Creates nothing enum value"
  @spec nothing() :: :nothing
  def nothing(), do: :nothing

  @doc "Creates restrict enum value"
  @spec restrict() :: :restrict
  def restrict(), do: :restrict

  @doc "Creates delete_all enum value"
  @spec delete_all() :: :delete_all
  def delete_all(), do: :delete_all

  @doc "Creates nilify_all enum value"
  @spec nilify_all() :: :nilify_all
  def nilify_all(), do: :nilify_all

  # Predicate functions for pattern matching
  @doc "Returns true if value is nothing variant"
  @spec is_nothing(t()) :: boolean()
  def is_nothing(:nothing), do: true
  def is_nothing(_), do: false

  @doc "Returns true if value is restrict variant"
  @spec is_restrict(t()) :: boolean()
  def is_restrict(:restrict), do: true
  def is_restrict(_), do: false

  @doc "Returns true if value is delete_all variant"
  @spec is_delete_all(t()) :: boolean()
  def is_delete_all(:delete_all), do: true
  def is_delete_all(_), do: false

  @doc "Returns true if value is nilify_all variant"
  @spec is_nilify_all(t()) :: boolean()
  def is_nilify_all(:nilify_all), do: true
  def is_nilify_all(_), do: false

end


defmodule OnReplaceAction do
  @moduledoc """
  OnReplaceAction enum generated from Haxe
  
  
 * On replace actions
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :raise |
    :mark_as_invalid |
    :nilify |
    :delete |
    :update

  @doc "Creates raise enum value"
  @spec raise() :: :raise
  def raise(), do: :raise

  @doc "Creates mark_as_invalid enum value"
  @spec mark_as_invalid() :: :mark_as_invalid
  def mark_as_invalid(), do: :mark_as_invalid

  @doc "Creates nilify enum value"
  @spec nilify() :: :nilify
  def nilify(), do: :nilify

  @doc "Creates delete enum value"
  @spec delete() :: :delete
  def delete(), do: :delete

  @doc "Creates update enum value"
  @spec update() :: :update
  def update(), do: :update

  # Predicate functions for pattern matching
  @doc "Returns true if value is raise variant"
  @spec is_raise(t()) :: boolean()
  def is_raise(:raise), do: true
  def is_raise(_), do: false

  @doc "Returns true if value is mark_as_invalid variant"
  @spec is_mark_as_invalid(t()) :: boolean()
  def is_mark_as_invalid(:mark_as_invalid), do: true
  def is_mark_as_invalid(_), do: false

  @doc "Returns true if value is nilify variant"
  @spec is_nilify(t()) :: boolean()
  def is_nilify(:nilify), do: true
  def is_nilify(_), do: false

  @doc "Returns true if value is delete variant"
  @spec is_delete(t()) :: boolean()
  def is_delete(:delete), do: true
  def is_delete(_), do: false

  @doc "Returns true if value is update variant"
  @spec is_update(t()) :: boolean()
  def is_update(:update), do: true
  def is_update(_), do: false

end


defmodule OnUpdateAction do
  @moduledoc """
  OnUpdateAction enum generated from Haxe
  
  
 * On update actions
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :nothing |
    :restrict |
    :update_all |
    :nilify_all

  @doc "Creates nothing enum value"
  @spec nothing() :: :nothing
  def nothing(), do: :nothing

  @doc "Creates restrict enum value"
  @spec restrict() :: :restrict
  def restrict(), do: :restrict

  @doc "Creates update_all enum value"
  @spec update_all() :: :update_all
  def update_all(), do: :update_all

  @doc "Creates nilify_all enum value"
  @spec nilify_all() :: :nilify_all
  def nilify_all(), do: :nilify_all

  # Predicate functions for pattern matching
  @doc "Returns true if value is nothing variant"
  @spec is_nothing(t()) :: boolean()
  def is_nothing(:nothing), do: true
  def is_nothing(_), do: false

  @doc "Returns true if value is restrict variant"
  @spec is_restrict(t()) :: boolean()
  def is_restrict(:restrict), do: true
  def is_restrict(_), do: false

  @doc "Returns true if value is update_all variant"
  @spec is_update_all(t()) :: boolean()
  def is_update_all(:update_all), do: true
  def is_update_all(_), do: false

  @doc "Returns true if value is nilify_all variant"
  @spec is_nilify_all(t()) :: boolean()
  def is_nilify_all(:nilify_all), do: true
  def is_nilify_all(_), do: false

end


defmodule ConstraintDefinition do
  @moduledoc """
  ConstraintDefinition enum generated from Haxe
  
  
 * Constraint definition
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:check, term()} |
    {:unique, term()} |
    {:foreign_key, term(), term()} |
    {:exclude, term()}

  @doc """
  Creates check enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec check(term()) :: {:check, term()}
  def check(arg0) do
    {:check, arg0}
  end

  @doc """
  Creates unique enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec unique(term()) :: {:unique, term()}
  def unique(arg0) do
    {:unique, arg0}
  end

  @doc """
  Creates foreign_key enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec foreign_key(term(), term()) :: {:foreign_key, term(), term()}
  def foreign_key(arg0, arg1) do
    {:foreign_key, arg0, arg1}
  end

  @doc """
  Creates exclude enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec exclude(term()) :: {:exclude, term()}
  def exclude(arg0) do
    {:exclude, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is check variant"
  @spec is_check(t()) :: boolean()
  def is_check({:check, _}), do: true
  def is_check(_), do: false

  @doc "Returns true if value is unique variant"
  @spec is_unique(t()) :: boolean()
  def is_unique({:unique, _}), do: true
  def is_unique(_), do: false

  @doc "Returns true if value is foreign_key variant"
  @spec is_foreign_key(t()) :: boolean()
  def is_foreign_key({:foreign_key, _}), do: true
  def is_foreign_key(_), do: false

  @doc "Returns true if value is exclude variant"
  @spec is_exclude(t()) :: boolean()
  def is_exclude({:exclude, _}), do: true
  def is_exclude(_), do: false

  @doc "Extracts value from check variant, returns {:ok, value} or :error"
  @spec get_check_value(t()) :: {:ok, term()} | :error
  def get_check_value({:check, value}), do: {:ok, value}
  def get_check_value(_), do: :error

  @doc "Extracts value from unique variant, returns {:ok, value} or :error"
  @spec get_unique_value(t()) :: {:ok, term()} | :error
  def get_unique_value({:unique, value}), do: {:ok, value}
  def get_unique_value(_), do: :error

  @doc "Extracts value from foreign_key variant, returns {:ok, value} or :error"
  @spec get_foreign_key_value(t()) :: {:ok, {term(), term()}} | :error
  def get_foreign_key_value({:foreign_key, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_foreign_key_value(_), do: :error

  @doc "Extracts value from exclude variant, returns {:ok, value} or :error"
  @spec get_exclude_value(t()) :: {:ok, term()} | :error
  def get_exclude_value({:exclude, value}), do: {:ok, value}
  def get_exclude_value(_), do: :error

end


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


defmodule OrderDirection do
  @moduledoc """
  OrderDirection enum generated from Haxe
  
  
 * Order by directions
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :a_s_c |
    :d_e_s_c

  @doc "Creates a_s_c enum value"
  @spec a_s_c() :: :a_s_c
  def a_s_c(), do: :a_s_c

  @doc "Creates d_e_s_c enum value"
  @spec d_e_s_c() :: :d_e_s_c
  def d_e_s_c(), do: :d_e_s_c

  # Predicate functions for pattern matching
  @doc "Returns true if value is a_s_c variant"
  @spec is_a_s_c(t()) :: boolean()
  def is_a_s_c(:a_s_c), do: true
  def is_a_s_c(_), do: false

  @doc "Returns true if value is d_e_s_c variant"
  @spec is_d_e_s_c(t()) :: boolean()
  def is_d_e_s_c(:d_e_s_c), do: true
  def is_d_e_s_c(_), do: false

end
