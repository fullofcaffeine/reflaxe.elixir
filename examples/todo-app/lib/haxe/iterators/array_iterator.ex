defmodule ArrayIterator do
  def has_next(struct) do
    struct.current < length(struct.array)
  end
  def next(_struct) do
    struct.array[struct.current + 1]
  end
end