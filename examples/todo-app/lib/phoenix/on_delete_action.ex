defmodule OnDeleteAction do
  @moduledoc """
  OnDeleteAction enum generated from Haxe
  
  
 * On delete actions
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :nothing |
    :restrict |
    :delete_all |
    :nilify_all

  @doc "Creates nothing enum value"
  @spec nothing() :: :nothing
  def nothing(), do: :nothing

  @doc "Creates restrict enum value"
  @spec restrict() :: :restrict
  def restrict(), do: :restrict

  @doc "Creates delete_all enum value"
  @spec delete_all() :: :delete_all
  def delete_all(), do: :delete_all

  @doc "Creates nilify_all enum value"
  @spec nilify_all() :: :nilify_all
  def nilify_all(), do: :nilify_all

  # Predicate functions for pattern matching
  @doc "Returns true if value is nothing variant"
  @spec is_nothing(t()) :: boolean()
  def is_nothing(:nothing), do: true
  def is_nothing(_), do: false

  @doc "Returns true if value is restrict variant"
  @spec is_restrict(t()) :: boolean()
  def is_restrict(:restrict), do: true
  def is_restrict(_), do: false

  @doc "Returns true if value is delete_all variant"
  @spec is_delete_all(t()) :: boolean()
  def is_delete_all(:delete_all), do: true
  def is_delete_all(_), do: false

  @doc "Returns true if value is nilify_all variant"
  @spec is_nilify_all(t()) :: boolean()
  def is_nilify_all(:nilify_all), do: true
  def is_nilify_all(_), do: false

end
