defmodule DataResult do
  @moduledoc """
  DataResult enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:success, term()} |
    {:error, term(), term()}

  @doc """
  Creates success enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec success(term()) :: {:success, term()}
  def success(arg0) do
    {:success, arg0}
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

  # Predicate functions for pattern matching
  @doc "Returns true if value is success variant"
  @spec is_success(t()) :: boolean()
  def is_success({:success, _}), do: true
  def is_success(_), do: false

  @doc "Returns true if value is error variant"
  @spec is_error(t()) :: boolean()
  def is_error({:error, _}), do: true
  def is_error(_), do: false

  @doc "Extracts value from success variant, returns {:ok, value} or :error"
  @spec get_success_value(t()) :: {:ok, term()} | :error
  def get_success_value({:success, value}), do: {:ok, value}
  def get_success_value(_), do: :error

  @doc "Extracts value from error variant, returns {:ok, value} or :error"
  @spec get_error_value(t()) :: {:ok, {term(), term()}} | :error
  def get_error_value({:error, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_error_value(_), do: :error

end
