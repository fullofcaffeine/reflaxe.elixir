defmodule AlertLevel do
  @moduledoc """
  AlertLevel enum generated from Haxe
  
  
 * Alert levels for system notifications
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :info |
    :warning |
    :error |
    :critical

  @doc "Creates info enum value"
  @spec info() :: :info
  def info(), do: :info

  @doc "Creates warning enum value"
  @spec warning() :: :warning
  def warning(), do: :warning

  @doc "Creates error enum value"
  @spec error() :: :error
  def error(), do: :error

  @doc "Creates critical enum value"
  @spec critical() :: :critical
  def critical(), do: :critical

  # Predicate functions for pattern matching
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

  @doc "Returns true if value is critical variant"
  @spec is_critical(t()) :: boolean()
  def is_critical(:critical), do: true
  def is_critical(_), do: false

end
