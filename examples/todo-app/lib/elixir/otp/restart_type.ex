defmodule RestartType do
  @moduledoc """
  RestartType enum generated from Haxe
  
  
 * Child restart strategy
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :permanent |
    :temporary |
    :transient

  @doc "Creates permanent enum value"
  @spec permanent() :: :permanent
  def permanent(), do: :permanent

  @doc "Creates temporary enum value"
  @spec temporary() :: :temporary
  def temporary(), do: :temporary

  @doc "Creates transient enum value"
  @spec transient() :: :transient
  def transient(), do: :transient

  # Predicate functions for pattern matching
  @doc "Returns true if value is permanent variant"
  @spec is_permanent(t()) :: boolean()
  def is_permanent(:permanent), do: true
  def is_permanent(_), do: false

  @doc "Returns true if value is temporary variant"
  @spec is_temporary(t()) :: boolean()
  def is_temporary(:temporary), do: true
  def is_temporary(_), do: false

  @doc "Returns true if value is transient variant"
  @spec is_transient(t()) :: boolean()
  def is_transient(:transient), do: true
  def is_transient(_), do: false

end
