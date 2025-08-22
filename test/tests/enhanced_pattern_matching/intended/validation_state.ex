defmodule ValidationState do
  @moduledoc """
  ValidationState enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :valid |
    {:invalid, term()} |
    {:pending, term()}

  @doc "Creates valid enum value"
  @spec valid() :: :valid
  def valid(), do: :valid

  @doc """
  Creates invalid enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec invalid(term()) :: {:invalid, term()}
  def invalid(arg0) do
    {:invalid, arg0}
  end

  @doc """
  Creates pending enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec pending(term()) :: {:pending, term()}
  def pending(arg0) do
    {:pending, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is valid variant"
  @spec is_valid(t()) :: boolean()
  def is_valid(:valid), do: true
  def is_valid(_), do: false

  @doc "Returns true if value is invalid variant"
  @spec is_invalid(t()) :: boolean()
  def is_invalid({:invalid, _}), do: true
  def is_invalid(_), do: false

  @doc "Returns true if value is pending variant"
  @spec is_pending(t()) :: boolean()
  def is_pending({:pending, _}), do: true
  def is_pending(_), do: false

  @doc "Extracts value from invalid variant, returns {:ok, value} or :error"
  @spec get_invalid_value(t()) :: {:ok, term()} | :error
  def get_invalid_value({:invalid, value}), do: {:ok, value}
  def get_invalid_value(_), do: :error

  @doc "Extracts value from pending variant, returns {:ok, value} or :error"
  @spec get_pending_value(t()) :: {:ok, term()} | :error
  def get_pending_value({:pending, value}), do: {:ok, value}
  def get_pending_value(_), do: :error

end
