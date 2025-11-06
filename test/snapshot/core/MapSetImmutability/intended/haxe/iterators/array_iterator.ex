defmodule ArrayIterator do
  def has_next(struct), do: struct.current < length(struct.array)
  def next(struct), do: struct.array[struct.current + 1]
end
