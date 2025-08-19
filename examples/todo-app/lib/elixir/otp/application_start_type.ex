defmodule ApplicationStartType do
  @moduledoc """
  ApplicationStartType enum generated from Haxe
  
  
   * Application start type - normal, temporary, or permanent
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :normal |
    :temporary |
    :permanent

  @doc "Creates normal enum value"
  @spec normal() :: :normal
  def normal(), do: :normal

  @doc "Creates temporary enum value"
  @spec temporary() :: :temporary
  def temporary(), do: :temporary

  @doc "Creates permanent enum value"
  @spec permanent() :: :permanent
  def permanent(), do: :permanent

  # Predicate functions for pattern matching
  @doc "Returns true if value is normal variant"
  @spec is_normal(t()) :: boolean()
  def is_normal(:normal), do: true
  def is_normal(_), do: false

  @doc "Returns true if value is temporary variant"
  @spec is_temporary(t()) :: boolean()
  def is_temporary(:temporary), do: true
  def is_temporary(_), do: false

  @doc "Returns true if value is permanent variant"
  @spec is_permanent(t()) :: boolean()
  def is_permanent(:permanent), do: true
  def is_permanent(_), do: false

end
