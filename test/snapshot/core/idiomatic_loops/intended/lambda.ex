defmodule Lambda do
  def array(it) do
    _ = it.iterator.()
    _ = Enum.each(v, fn item -> item = Enum.concat(item, [item]) end)
    []
  end
  def list(it) do
    _ = it.iterator.()
    _ = Enum.each(v, fn item -> item = Enum.concat(item, [item]) end)
    []
  end
  def concat(a, b) do
    _ = a.iterator.()
    _ = Enum.each(v, fn item -> item = Enum.concat(item, [item]) end)
    _ = b.iterator.()
    _ = Enum.each(v, fn item -> item = Enum.concat(item, [item]) end)
    []
  end
  def map(it, f) do
    Enum.map(it, f)
  end
  def filter(it, f) do
    Enum.filter(it, f)
  end
  def fold(it, f, first) do
    Enum.reduce(it, first, f)
  end
  def count(it, pred) do
    if (Kernel.is_nil(pred)) do
      Enum.count(it)
    else
      Enum.count(it, pred)
    end
  end
  def exists(it, f) do
    Enum.any?(it, f)
  end
  def foreach(it, f) do
    Enum.all?(it, f)
  end
  def find(it, f) do
    Enum.find(it, f)
  end
  def empty(it) do
    Enum.empty?(it)
  end
  def index_of(it, v) do
    result = Enum.find_index(it, fn x -> x == v end)
    if (Kernel.is_nil(result)), do: -1, else: result
  end
  def has(it, v) do
    Enum.member?(it, v)
  end
  def iter(it, f) do
    Enum.each(it, f)
  end
end
