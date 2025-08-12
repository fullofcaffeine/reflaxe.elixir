defmodule DataProcessor do
  @moduledoc """
  Behavior module defining callback specifications.
  Generated from Haxe @:behaviour class.
  """

  @callback nit(any()) :: any()
  @callback rocess_item(any(), any()) :: any()
  @callback rocess_batch(list(), any()) :: any()
  @callback alidate_data(any()) :: boolean()
  @callback andle_error(any(), any()) :: String.t()
  @callback et_stats() :: any()
  @callback leanup(any()) :: any()

  @optional_callbacks [et_stats: 0, leanup: 1]

end
