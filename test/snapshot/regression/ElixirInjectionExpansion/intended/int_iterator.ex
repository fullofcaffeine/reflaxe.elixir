defmodule IntIterator do
  def new(min_param, max_param) do
    struct = %{:min => nil, :max => nil}
    struct = %{struct | min: min_param}
    struct = %{struct | max: max_param}
    struct
  end
  def has_next(struct) do
    struct.min < struct.max
    item
  end
  def next(struct) do
    struct.min + 1
    item
  end
end
