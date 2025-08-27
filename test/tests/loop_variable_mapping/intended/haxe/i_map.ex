defmodule IMap do
  @moduledoc """
  IMap behavior generated from Haxe interface
  """

  @callback get(K.t()) :: Null.t()
  @callback set(K.t(), V.t()) :: nil
  @callback exists(K.t()) :: boolean()
  @callback remove(K.t()) :: boolean()
  @callback keys() :: Iterator.t()
  @callback iterator() :: Iterator.t()
  @callback key_value_iterator() :: KeyValueIterator.t()
  @callback copy() :: IMap.t()
  @callback format() :: String.t()
  @callback clear() :: nil
end
