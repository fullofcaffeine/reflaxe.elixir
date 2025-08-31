defmodule ArrayIterator do
  def new(array) do
    %{:current => 0, :array => array}
  end
  def has_next(struct) do
    struct.current < struct.array.length
  end
  def next(struct) do
    struct.array[struct.current + 1]
  end
end