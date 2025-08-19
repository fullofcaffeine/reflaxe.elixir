defmodule ChildType do
  @moduledoc """
  ChildType enum generated from Haxe
  
  
 * Child type
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :worker |
    :supervisor

  @doc "Creates worker enum value"
  @spec worker() :: :worker
  def worker(), do: :worker

  @doc "Creates supervisor enum value"
  @spec supervisor() :: :supervisor
  def supervisor(), do: :supervisor

  # Predicate functions for pattern matching
  @doc "Returns true if value is worker variant"
  @spec is_worker(t()) :: boolean()
  def is_worker(:worker), do: true
  def is_worker(_), do: false

  @doc "Returns true if value is supervisor variant"
  @spec is_supervisor(t()) :: boolean()
  def is_supervisor(:supervisor), do: true
  def is_supervisor(_), do: false

end
