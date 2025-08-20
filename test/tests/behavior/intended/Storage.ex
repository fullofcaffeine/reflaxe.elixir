defmodule Storage do
  @moduledoc """
  Behavior module defining callback specifications.
  Generated from Haxe @:behaviour class.
  """

  @callback init(any()) :: any()
  @callback get(String.t()) :: any()
  @callback put(String.t(), any()) :: boolean()
  @callback delete(String.t()) :: boolean()
  @callback list() :: list()

end
