defmodule FlashType do
  @moduledoc """
  FlashType enum generated from Haxe
  
  
 * Standard flash message types used in Phoenix applications
 * 
 * These correspond to common CSS classes and UI patterns:
 * - Info: Blue, informational messages
 * - Success: Green, confirmation messages  
 * - Warning: Yellow, caution messages
 * - Error: Red, error messages
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :info |
    :success |
    :warning |
    :error

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

end
