defmodule IMap do
  @moduledoc """
  IMap behavior generated from Haxe interface
  """

  @callback keys() :: Iterator.t()
  @callback iterator() :: Iterator.t()
  @callback key_value_iterator() :: KeyValueIterator.t()
end
