defmodule EFieldKind do
  @moduledoc """
  EFieldKind enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :normal |
    :safe

  @doc "Creates normal enum value"
  @spec normal() :: :normal
  def normal(), do: :normal

  @doc "Creates safe enum value"
  @spec safe() :: :safe
  def safe(), do: :safe

  # Predicate functions for pattern matching
  @doc "Returns true if value is normal variant"
  @spec is_normal(t()) :: boolean()
  def is_normal(:normal), do: true
  def is_normal(_), do: false

  @doc "Returns true if value is safe variant"
  @spec is_safe(t()) :: boolean()
  def is_safe(:safe), do: true
  def is_safe(_), do: false

end
