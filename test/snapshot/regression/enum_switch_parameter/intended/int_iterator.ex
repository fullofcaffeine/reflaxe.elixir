defmodule IntIterator do
  @min nil
  @max nil
  def has_next(struct) do
    struct.min < struct.max
  end
  def next(struct) do
    struct.min + 1
  end
end