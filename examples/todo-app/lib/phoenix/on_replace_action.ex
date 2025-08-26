defmodule OnReplaceAction do
  @moduledoc """
  OnReplaceAction enum generated from Haxe
  
  
   * On replace actions
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :raise |
    :mark_as_invalid |
    :nilify |
    :delete |
    :update

  @doc "Creates raise enum value"
  @spec raise() :: :raise
  def raise(), do: :raise

  @doc "Creates mark_as_invalid enum value"
  @spec mark_as_invalid() :: :mark_as_invalid
  def mark_as_invalid(), do: :mark_as_invalid

  @doc "Creates nilify enum value"
  @spec nilify() :: :nilify
  def nilify(), do: :nilify

  @doc "Creates delete enum value"
  @spec delete() :: :delete
  def delete(), do: :delete

  @doc "Creates update enum value"
  @spec update() :: :update
  def update(), do: :update

  # Predicate functions for pattern matching
  @doc "Returns true if value is raise variant"
  @spec is_raise(t()) :: boolean()
  def is_raise(:raise), do: true
  def is_raise(_), do: false

  @doc "Returns true if value is mark_as_invalid variant"
  @spec is_mark_as_invalid(t()) :: boolean()
  def is_mark_as_invalid(:mark_as_invalid), do: true
  def is_mark_as_invalid(_), do: false

  @doc "Returns true if value is nilify variant"
  @spec is_nilify(t()) :: boolean()
  def is_nilify(:nilify), do: true
  def is_nilify(_), do: false

  @doc "Returns true if value is delete variant"
  @spec is_delete(t()) :: boolean()
  def is_delete(:delete), do: true
  def is_delete(_), do: false

  @doc "Returns true if value is update variant"
  @spec is_update(t()) :: boolean()
  def is_update(:update), do: true
  def is_update(_), do: false

end
