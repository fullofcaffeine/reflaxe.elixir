defmodule ArrayKeyValueIterator do
  @array nil
  @current nil
  def has_next(struct) do
    struct.current < length(struct.array)
  end
  def next(struct) do
    index = struct.current + 1
    %{:key => index, :value => struct.array[index]}
  end
end