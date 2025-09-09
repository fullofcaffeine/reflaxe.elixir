defmodule ArrayKeyValueIterator do
  @array nil
  @current nil
  def has_next(struct) do
    struct.current < length(struct.array)
  end
  def next(struct) do
    index = struct.current
    %{:key => index, :value => Enum.at(struct.array, index)}
  end
end
