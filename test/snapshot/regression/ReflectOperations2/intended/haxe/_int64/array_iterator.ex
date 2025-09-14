defmodule ArrayIterator do
  def new(array) do
    %{:current => 0, :array => array}
  end
  def has_next(struct) do
    struct.current < length(struct.array)
  end
  def next(_struct) do
    struct.array[struct.current + 1]
  end
end