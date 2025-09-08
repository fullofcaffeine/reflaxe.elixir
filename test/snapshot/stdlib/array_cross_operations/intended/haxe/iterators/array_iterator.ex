defmodule ArrayIterator do
  @array nil
  @current nil
  def has_next() do
    struct.current < length(struct.array)
  end
  def next() do
    struct.array[struct.current + 1]
  end
end