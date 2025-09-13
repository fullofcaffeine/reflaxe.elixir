defmodule ArrayIterator do
  @array nil
  @current nil
  def has_next(struct) do
    struct.current < length(struct.array)
  end
  def next(struct) do
    struct.array[struct.current + 1]
  end
end