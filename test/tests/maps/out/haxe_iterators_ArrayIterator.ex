defmodule ArrayIterator do
  @moduledoc """
  ArrayIterator module generated from Haxe
  
  
	This iterator is used only when `Array<T>` is passed to `Iterable<T>`

  """

  # Instance functions
  @doc "
		See `Iterator.hasNext`
	"
  @spec has_next() :: TAbstract(Bool,[]).t()
  def has_next() do
    self().current < self().array.length
  end

  @doc "
		See `Iterator.next`
	"
  @spec next() :: TInst(haxe.Iterators.ArrayIterator.T,[]).t()
  def next() do
    # TODO: Implement expression type: TArray
  end

end
