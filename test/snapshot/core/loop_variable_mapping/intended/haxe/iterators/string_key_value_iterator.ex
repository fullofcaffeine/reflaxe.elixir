defmodule StringKeyValueIterator do
  def new(s) do
    %{:offset => 0, :s => s}
  end
  def has_next(struct) do
    struct.offset < struct.s.length
  end
  def next(struct) do
    %{:key => struct.offset, :value => s = struct.s
index = struct.offset + 1
s.cca(index)}
  end
end