defmodule OnUpdateAction do
  @moduledoc """
  OnUpdateAction enum generated from Haxe
  
  
   * On update actions
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :nothing |
    :restrict |
    :update_all |
    :nilify_all

  @doc "Creates nothing enum value"
  @spec nothing() :: :nothing
  def nothing(), do: :nothing

  @doc "Creates restrict enum value"
  @spec restrict() :: :restrict
  def restrict(), do: :restrict

  @doc "Creates update_all enum value"
  @spec update_all() :: :update_all
  def update_all(), do: :update_all

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

  @doc "Returns true if value is update_all variant"
  @spec is_update_all(t()) :: boolean()
  def is_update_all(:update_all), do: true
  def is_update_all(_), do: false

  @doc "Returns true if value is nilify_all variant"
  @spec is_nilify_all(t()) :: boolean()
  def is_nilify_all(:nilify_all), do: true
  def is_nilify_all(_), do: false

end
