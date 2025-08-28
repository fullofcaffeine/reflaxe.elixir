defmodule Logger do
  @moduledoc """
  Behavior module defining callback specifications.
  Generated from Haxe @:behaviour class.
  """

  @callback log(String.t()) :: any()
  @callback debug(String.t()) :: any()
  @callback error(String.t(), any()) :: any()

end
