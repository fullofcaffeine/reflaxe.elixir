defmodule ChangesetAction do
  @moduledoc """
  ChangesetAction enum generated from Haxe
  
  
   * Changeset actions
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :insert |
    :update |
    :delete |
    :replace |
    :ignore

  @doc "Creates insert enum value"
  @spec insert() :: :insert
  def insert(), do: :insert

  @doc "Creates update enum value"
  @spec update() :: :update
  def update(), do: :update

  @doc "Creates delete enum value"
  @spec delete() :: :delete
  def delete(), do: :delete

  @doc "Creates replace enum value"
  @spec replace() :: :replace
  def replace(), do: :replace

  @doc "Creates ignore enum value"
  @spec ignore() :: :ignore
  def ignore(), do: :ignore

  # Predicate functions for pattern matching
  @doc "Returns true if value is insert variant"
  @spec is_insert(t()) :: boolean()
  def is_insert(:insert), do: true
  def is_insert(_), do: false

  @doc "Returns true if value is update variant"
  @spec is_update(t()) :: boolean()
  def is_update(:update), do: true
  def is_update(_), do: false

  @doc "Returns true if value is delete variant"
  @spec is_delete(t()) :: boolean()
  def is_delete(:delete), do: true
  def is_delete(_), do: false

  @doc "Returns true if value is replace variant"
  @spec is_replace(t()) :: boolean()
  def is_replace(:replace), do: true
  def is_replace(_), do: false

  @doc "Returns true if value is ignore variant"
  @spec is_ignore(t()) :: boolean()
  def is_ignore(:ignore), do: true
  def is_ignore(_), do: false

end
