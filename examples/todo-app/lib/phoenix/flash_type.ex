defmodule FlashType do
  @moduledoc """
  FlashType enum generated from Haxe
  
  
 * Flash message types
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :info |
    :success |
    :warning |
    :error |
    {:custom, term()}

  @doc "Creates info enum value"
  @spec info() :: :info
  def info(), do: :info

  @doc "Creates success enum value"
  @spec success() :: :success
  def success(), do: :success

  @doc "Creates warning enum value"
  @spec warning() :: :warning
  def warning(), do: :warning

  @doc "Creates error enum value"
  @spec error() :: :error
  def error(), do: :error

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
  @doc "Returns true if value is info variant"
  @spec is_info(t()) :: boolean()
  def is_info(:info), do: true
  def is_info(_), do: false

  @doc "Returns true if value is success variant"
  @spec is_success(t()) :: boolean()
  def is_success(:success), do: true
  def is_success(_), do: false

  @doc "Returns true if value is warning variant"
  @spec is_warning(t()) :: boolean()
  def is_warning(:warning), do: true
  def is_warning(_), do: false

  @doc "Returns true if value is error variant"
  @spec is_error(t()) :: boolean()
  def is_error(:error), do: true
  def is_error(_), do: false

  @doc "Returns true if value is custom variant"
  @spec is_custom(t()) :: boolean()
  def is_custom({:custom, _}), do: true
  def is_custom(_), do: false

  @doc "Extracts value from custom variant, returns {:ok, value} or :error"
  @spec get_custom_value(t()) :: {:ok, term()} | :error
  def get_custom_value({:custom, value}), do: {:ok, value}
  def get_custom_value(_), do: :error

end
