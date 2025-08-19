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
