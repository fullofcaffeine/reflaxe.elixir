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
