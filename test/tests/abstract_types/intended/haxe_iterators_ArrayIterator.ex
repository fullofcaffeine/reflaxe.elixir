defmodule ArrayIterator do
  @moduledoc """
  ArrayIterator module generated from Haxe
  
  
	This iterator is used only when `Array<T>` is passed to `Iterable<T>`

  """

  # Instance functions
  @doc "
		See `Iterator.hasNext`
	"
  @spec has_next() :: boolean()
  def has_next() do
    self().current < self().array.length
  end

  @doc "
		See `Iterator.next`
	"
  @spec next() :: T.t()
  def next() do
    Enum.at(self().array, self().current + 1)
  end

end
