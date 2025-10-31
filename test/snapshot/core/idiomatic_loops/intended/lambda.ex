defmodule Lambda do
  def array(it) do
    v = it.iterator.()
    Enum.reduce(Map.values(v), [], fn entry, acc -> if (Kernel.length(entry.metas) > 0), do: acc ++ [entry.metas[0]], else: acc end)
  end
  def list(it) do
    v = it.iterator.()
    Enum.reduce(Map.values(v), [], fn entry, acc -> if (Kernel.length(entry.metas) > 0), do: acc ++ [entry.metas[0]], else: acc end)
  end
  def concat(a, b) do
    v = a.iterator.()
    Enum.each(v, fn item -> item = Enum.concat(item, [item]) end)
    v = b.iterator.()
    Enum.each(v, fn item -> item = Enum.concat(item, [item]) end)
    []
  end
  def map(it, f) do
    v = it.iterator.()
    Enum.reduce(Map.values(v), [], fn entry, acc -> if (Kernel.length(entry.metas) > 0), do: acc ++ [entry.metas[0]], else: acc end)
  end
  def filter(it, f) do
    v = it.iterator.()
    Enum.reduce(Map.values(v), [], fn entry, acc -> if (Kernel.length(entry.metas) > 0), do: acc ++ [entry.metas[0]], else: acc end)
  end
  def fold(it, f, first) do
    _ = it.iterator.()
    Enum.each(first, fn item -> first = item.(item, first) end)
    first
  end
  def count(it, pred) do
    n = 0
    if (Kernel.is_nil(pred)) do
      _ = it.iterator.()
      Enum.each(_, fn item -> item + 1 end)
    else
      v = it.iterator.()
      Enum.each(v, fn item ->
        if (pred.(item)), do: n = n + 1
      end)
    end
    n
  end
  def exists(it, f) do
    v = it.iterator.()
    Enum.each(v, fn item ->
      if (item.(item)), do: true
    end)
    false
  end
  def foreach(it, f) do
    v = it.iterator.()
    Enum.each(v, fn _ ->
      if (not f.(v2)), do: false
    end)
    true
  end
  def find(it, f) do
    Enum.find(v, fn item -> item.(item) end)
  end
  def empty(it) do
    _ = it.iterator.()
    Enum.each(_, fn _ -> false end)
    true
  end
  def index_of(it, v) do
    i = 0
    x = it.iterator.()
    Enum.each(x, fn item ->
      if (item == v), do: i
      i + 1
    end)
    -1
  end
  def has(it, v) do
    x = it.iterator.()
    Enum.each(x, fn item ->
      if (item == item), do: true
    end)
    false
  end
  def iter(it, f) do
    x = it.iterator.()
    Enum.each(x, fn item -> item.(item) end)
  end
end
