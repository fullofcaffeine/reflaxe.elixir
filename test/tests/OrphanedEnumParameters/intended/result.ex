defmodule Result do
  @moduledoc """
  Result enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:success, term(), term()} |
    {:warning, term()} |
    {:error, term(), term()} |
    :pending

  @doc """
  Creates success enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec success(term(), term()) :: {:success, term(), term()}
  def success(arg0, arg1) do
    {:success, arg0, arg1}
  end

  @doc """
  Creates warning enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec warning(term()) :: {:warning, term()}
  def warning(arg0) do
    {:warning, arg0}
  end

  @doc """
  Creates error enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec error(term(), term()) :: {:error, term(), term()}
  def error(arg0, arg1) do
    {:error, arg0, arg1}
  end

  @doc "Creates pending enum value"
  @spec pending() :: :pending
  def pending(), do: :pending

  # Predicate functions for pattern matching
  @doc "Returns true if value is success variant"
  @spec is_success(t()) :: boolean()
  def is_success({:success, _}), do: true
  def is_success(_), do: false

  @doc "Returns true if value is warning variant"
  @spec is_warning(t()) :: boolean()
  def is_warning({:warning, _}), do: true
  def is_warning(_), do: false

  @doc "Returns true if value is error variant"
  @spec is_error(t()) :: boolean()
  def is_error({:error, _}), do: true
  def is_error(_), do: false

  @doc "Returns true if value is pending variant"
  @spec is_pending(t()) :: boolean()
  def is_pending(:pending), do: true
  def is_pending(_), do: false

  @doc "Extracts value from success variant, returns {:ok, value} or :error"
  @spec get_success_value(t()) :: {:ok, {term(), term()}} | :error
  def get_success_value({:success, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_success_value(_), do: :error

  @doc "Extracts value from warning variant, returns {:ok, value} or :error"
  @spec get_warning_value(t()) :: {:ok, term()} | :error
  def get_warning_value({:warning, value}), do: {:ok, value}
  def get_warning_value(_), do: :error

  @doc "Extracts value from error variant, returns {:ok, value} or :error"
  @spec get_error_value(t()) :: {:ok, {term(), term()}} | :error
  def get_error_value({:error, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_error_value(_), do: :error

end
