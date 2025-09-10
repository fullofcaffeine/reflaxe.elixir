defmodule ArrayIterator do
  @array nil
  @current nil
  def has_next(_struct) do
    struct.current < length(struct.array)
  end
  def next(_struct) do
    struct.array[struct.current + 1]
  end
end