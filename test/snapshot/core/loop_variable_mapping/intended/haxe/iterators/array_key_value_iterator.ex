defmodule ArrayKeyValueIterator do
  def new(array) do
    %{:current => 0, :array => array}
  end
  def has_next(struct) do
    struct.current < struct.array.length
  end
  def next(struct) do
    %{:value => struct.array[struct.current], :key => struct.current + 1}
  end
end