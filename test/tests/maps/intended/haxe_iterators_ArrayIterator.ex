defmodule ArrayIterator do
  use Bitwise
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
    __MODULE__.current < length(__MODULE__.array)
  end

  @doc "
		See `Iterator.next`
	"
  @spec next() :: T.t()
  def next() do
    Enum.at(__MODULE__.array, __MODULE__.current + 1)
  end

end
