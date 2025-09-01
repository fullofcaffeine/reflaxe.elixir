defmodule IntIterator do
  def new(min, max) do
    %{:min => min, :max => max}
  end
  def has_next(struct) do
    struct.min < struct.max
  end
  def next(struct) do
    struct.min + 1
  end
end