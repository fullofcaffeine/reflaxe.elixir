defmodule Lambda do
  def array(it) do
    arr = []
    v = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {v, :ok}, fn _, {acc_v, acc_state} ->
  if (acc_v.has_next()) do
    arr ++ [(acc_v.next())]
    {:cont, {acc_v, acc_state}}
  else
    {:halt, {acc_v, acc_state}}
  end
end)
    arr
  end
  def list(it) do
    arr = []
    v = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {v, :ok}, fn _, {acc_v, acc_state} ->
  if (acc_v.has_next()) do
    arr ++ [(acc_v.next())]
    {:cont, {acc_v, acc_state}}
  else
    {:halt, {acc_v, acc_state}}
  end
end)
    arr
  end
  def concat(a, b) do
    arr = []
    v = a.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {v, :ok}, fn _, {acc_v, acc_state} ->
  if (acc_v.has_next()) do
    arr ++ [(acc_v.next())]
    {:cont, {acc_v, acc_state}}
  else
    {:halt, {acc_v, acc_state}}
  end
end)
    v = b.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {v, :ok}, fn _, {acc_v, acc_state} ->
  if (acc_v.has_next()) do
    arr ++ [(acc_v.next())]
    {:cont, {acc_v, acc_state}}
  else
    {:halt, {acc_v, acc_state}}
  end
end)
    arr
  end
  def map(it, f) do
    arr = []
    v = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {v, :ok}, fn _, {acc_v, acc_state} ->
  if (acc_v.has_next()) do
    arr ++ [f.((acc_v.next()))]
    {:cont, {acc_v, acc_state}}
  else
    {:halt, {acc_v, acc_state}}
  end
end)
    arr
  end
  def filter(it, f) do
    arr = []
    v = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {v, :ok}, fn _, {acc_v, acc_state} ->
  if (acc_v.has_next()) do
    if (f.(acc_v)), do: arr ++ [(acc_v.next())]
    {:cont, {acc_v, acc_state}}
  else
    {:halt, {acc_v, acc_state}}
  end
end)
    arr
  end
  def fold(it, f, first) do
    acc = first
    v = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {v, acc, :ok}, fn _, {acc_v, acc_acc, acc_state} -> nil end)
    acc
  end
  def count(_it, pred) do
    n = 0
    if (pred == nil) do
      item = _it.iterator()
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {item, n, :ok}, fn _, {acc_item, acc_n, acc_state} ->
  if (acc_item.has_next()) do
    _item = acc_item.next()
    acc_n = acc_n + 1
    {:cont, {acc_item, acc_n, acc_state}}
  else
    {:halt, {acc_item, acc_n, acc_state}}
  end
end)
    else
      v = _it.iterator()
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {n, v, :ok}, fn _, {acc_n, acc_v, acc_state} -> nil end)
    end
    n
  end
  def exists(it, f) do
    v = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {v, :ok}, fn _, {acc_v, acc_state} -> nil end)
    false
  end
  def foreach(it, f) do
    v = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {v, :ok}, fn _, {acc_v, acc_state} -> nil end)
    true
  end
  def find(it, f) do
    v = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {v, :ok}, fn _, {acc_v, acc_state} ->
  if (acc_v.has_next()) do
    if (f.(acc_v)) do
      (acc_v.next())
    end
    {:cont, {acc_v, acc_state}}
  else
    {:halt, {acc_v, acc_state}}
  end
end)
    nil
  end
  def empty(it) do
    item = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {item, :ok}, fn _, {acc_item, acc_state} ->
  if (acc_item.has_next()) do
    _item = acc_item.next()
    false
    {:cont, {acc_item, acc_state}}
  else
    {:halt, {acc_item, acc_state}}
  end
end)
    true
  end
  def index_of(it, v) do
    i = 0
    x = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {i, x, :ok}, fn _, {acc_i, acc_x, acc_state} -> nil end)
    -1
  end
  def has(it, v) do
    x = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {x, :ok}, fn _, {acc_x, acc_state} -> nil end)
    false
  end
  def iter(it, f) do
    x = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {x, :ok}, fn _, {acc_x, acc_state} ->
  if (acc_x.has_next()) do
    f.((acc_x.next()))
    {:cont, {acc_x, acc_state}}
  else
    {:halt, {acc_x, acc_state}}
  end
end)
  end
end