# Example enum compilation output from improved EnumCompiler

# Simple enum (Status) - compiled to atoms with proper typespec
defmodule Status do
  @moduledoc """
  Status enum generated from Haxe
  
  Test status enum
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :none |
    :ready |
    :error

  @doc "Creates none enum value"
  @spec none() :: :none
  def none(), do: :none

  @doc "Creates ready enum value"
  @spec ready() :: :ready
  def ready(), do: :ready

  @doc "Creates error enum value"
  @spec error() :: :error
  def error(), do: :error

  # Predicate functions for pattern matching
  @doc "Returns true if value is none variant"
  @spec is_none(t()) :: boolean()
  def is_none(:none), do: true
  def is_none(_), do: false

  @doc "Returns true if value is ready variant"
  @spec is_ready(t()) :: boolean()
  def is_ready(:ready), do: true
  def is_ready(_), do: false

  @doc "Returns true if value is error variant"
  @spec is_error(t()) :: boolean()
  def is_error(:error), do: true
  def is_error(_), do: false
end

# Parameterized enum (Result<T>) - compiled to tagged tuples
defmodule Result do
  @moduledoc """
  Result enum generated from Haxe
  
  Result type for operations
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:ok, String.t()} |
    {:error, String.t()}

  @doc """
  Creates ok enum value with parameters
  
  ## Parameters
  - `arg0`: String.t()
  """
  @spec ok(String.t()) :: {:ok, String.t()}
  def ok(arg0) do
    {:ok, arg0}
  end

  @doc """
  Creates error enum value with parameters
  
  ## Parameters
  - `arg0`: String.t()
  """
  @spec error(String.t()) :: {:error, String.t()}
  def error(arg0) do
    {:error, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is ok variant"
  @spec is_ok(t()) :: boolean()
  def is_ok({:ok, _}), do: true
  def is_ok(_), do: false

  @doc "Returns true if value is error variant"
  @spec is_error(t()) :: boolean()
  def is_error({:error, _}), do: true
  def is_error(_), do: false

  @doc "Extracts value from ok variant, returns {:ok, value} or :error"
  @spec get_ok_value(t()) :: {:ok, String.t()} | :error
  def get_ok_value({:ok, value}), do: {:ok, value}
  def get_ok_value(_), do: :error

  @doc "Extracts value from error variant, returns {:ok, value} or :error"
  @spec get_error_value(t()) :: {:ok, String.t()} | :error
  def get_error_value({:error, value}), do: {:ok, value}
  def get_error_value(_), do: :error
end

# Mixed enum (Message) - atoms + tagged tuples
defmodule Message do
  @moduledoc """
  Message enum generated from Haxe
  
  Message types
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:info, String.t()} |
    {:warning, String.t(), integer()} |
    :critical

  @doc """
  Creates info enum value with parameters
  
  ## Parameters
  - `arg0`: String.t()
  """
  @spec info(String.t()) :: {:info, String.t()}
  def info(arg0) do
    {:info, arg0}
  end

  @doc """
  Creates warning enum value with parameters
  
  ## Parameters
  - `arg0`: String.t()
  - `arg1`: integer()
  """
  @spec warning(String.t(), integer()) :: {:warning, String.t(), integer()}
  def warning(arg0, arg1) do
    {:warning, arg0, arg1}
  end

  @doc "Creates critical enum value"
  @spec critical() :: :critical
  def critical(), do: :critical

  # Predicate functions for pattern matching
  @doc "Returns true if value is info variant"
  @spec is_info(t()) :: boolean()
  def is_info({:info, _}), do: true
  def is_info(_), do: false

  @doc "Returns true if value is warning variant"
  @spec is_warning(t()) :: boolean()
  def is_warning({:warning, _, _}), do: true
  def is_warning(_), do: false

  @doc "Returns true if value is critical variant"
  @spec is_critical(t()) :: boolean()
  def is_critical(:critical), do: true
  def is_critical(_), do: false

  @doc "Extracts value from info variant, returns {:ok, value} or :error"
  @spec get_info_value(t()) :: {:ok, String.t()} | :error
  def get_info_value({:info, value}), do: {:ok, value}
  def get_info_value(_), do: :error

  @doc "Extracts value from warning variant, returns {:ok, value} or :error"
  @spec get_warning_value(t()) :: {:ok, {String.t(), integer()}} | :error
  def get_warning_value({:warning, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_warning_value(_), do: :error
end

# Option<T> enum - generic type with proper typing
defmodule Option do
  @moduledoc """
  Option enum generated from Haxe
  
  Optional value container
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :none |
    {:some, term()}

  @doc "Creates none enum value"
  @spec none() :: :none
  def none(), do: :none

  @doc """
  Creates some enum value with parameters
  
  ## Parameters
  - `arg0`: term()
  """
  @spec some(term()) :: {:some, term()}
  def some(arg0) do
    {:some, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is none variant"
  @spec is_none(t()) :: boolean()
  def is_none(:none), do: true
  def is_none(_), do: false

  @doc "Returns true if value is some variant"
  @spec is_some(t()) :: boolean()
  def is_some({:some, _}), do: true
  def is_some(_), do: false

  @doc "Extracts value from some variant, returns {:ok, value} or :error"
  @spec get_some_value(t()) :: {:ok, term()} | :error
  def get_some_value({:some, value}), do: {:ok, value}
  def get_some_value(_), do: :error
end