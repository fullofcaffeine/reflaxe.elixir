defmodule ArrayIterator do
  def has_next() do
    struct.current < length(self.array)
  end
  def next() do
    self.array[self.current + 1]
  end
end