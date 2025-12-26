defmodule Lambda do
  def array(it) do
    arr = []
    v = it.iterator.()
    Enum.each(arr, fn item -> _ = arr ++ [v] end)
    nil
    arr
  end
  def list(it) do
    arr = []
    v = it.iterator.()
    Enum.each(arr, fn item -> _ = arr ++ [v] end)
    nil
    arr
  end
  def concat(a, b) do
    arr = []
    v = a.iterator.()
    Enum.each(arr, fn item -> _ = arr ++ [v] end)
    nil
    v = b.iterator.()
    Enum.each(arr, fn item -> _ = arr ++ [v] end)
    nil
    arr
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
