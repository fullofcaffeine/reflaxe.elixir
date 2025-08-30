defmodule ArrayIterator do
  def new() do
    fn array -> current = 0
array = array end
  end
  def hasNext() do
    fn -> struct.current < struct.array.length end
  end
  def next() do
    fn -> struct.array[struct.current + 1] end
  end
end