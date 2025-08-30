defmodule ArrayIterator do
  def new(struct, array) do
    fn array -> current = 0
array = array end
  end
  def hasNext(struct) do
    fn -> struct.current < struct.array.length end
  end
  def next(struct) do
    fn -> struct.array[struct.current + 1] end
  end
end